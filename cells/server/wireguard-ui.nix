{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.my.wireguardUi;
  secretsFile = "${inputs.nix-secrets}/secrets.yaml";
  privateKeySecret = "server_db_private_key";
  adminPasswordHashSecret = "server_users_admin_password_hash";
in
{
  options.my.wireguardUi = {
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/wireguard-ui";
      description = "Runtime state directory used by wireguard-ui.";
    };

    bindAddress = mkOption {
      type = types.str;
      default = "127.0.0.1:5000";
      description = "Address wireguard-ui binds to. Keep loopback unless a reverse proxy protects it.";
    };

    endpointAddress = mkOption {
      type = types.str;
      default = "";
      description = "Public WireGuard endpoint address exposed to generated clients.";
    };

    dnsServers = mkOption {
      type = types.listOf types.str;
      default = [ "1.1.1.1" ];
      description = "DNS servers written to WireGuard client configs.";
    };

    addresses = mkOption {
      type = types.listOf types.str;
      default = [ "10.252.1.0/24" ];
      description = "WireGuard interface address ranges managed by wireguard-ui.";
    };

    listenPort = mkOption {
      type = types.str;
      default = "51820";
      description = "WireGuard listen port.";
    };
  };

  config.my.branches."wireguard-ui".nixosModules = [
    (
      { config, pkgs, ... }:
      let
        json = pkgs.formats.json { };
        globalSettings = json.generate "wireguard-ui-global-settings.json" {
          endpoint_address = cfg.endpointAddress;
          dns_servers = cfg.dnsServers;
          mtu = "1450";
          persistent_keepalive = "15";
          firewall_mark = "0xca6c";
          table = "auto";
          config_file_path = "/etc/wireguard/wg0.conf";
          updated_at = "1970-01-01T00:00:00Z";
        };
        hashes = json.generate "wireguard-ui-hashes.json" {
          client = "none";
          server = "none";
        };
        interfaces = json.generate "wireguard-ui-interfaces.json" {
          addresses = cfg.addresses;
          listen_port = cfg.listenPort;
          updated_at = "1970-01-01T00:00:00Z";
          post_up = "";
          pre_down = "";
          post_down = "";
        };
      in
      {
        assertions = [
          {
            assertion = builtins.pathExists secretsFile;
            message = "The wireguard-ui branch requires ${secretsFile} to exist.";
          }
        ];

        environment.systemPackages = [ pkgs.wireguard-ui ];

        sops.secrets.${privateKeySecret} = {
          sopsFile = secretsFile;
          owner = "root";
          group = "root";
          mode = "0400";
        };
        sops.secrets.${adminPasswordHashSecret} = {
          sopsFile = secretsFile;
          owner = "root";
          group = "root";
          mode = "0400";
        };

        systemd.tmpfiles.rules = [
          "d ${cfg.dataDir} 0700 root root -"
          "d ${cfg.dataDir}/db 0700 root root -"
          "d ${cfg.dataDir}/db/server 0700 root root -"
          "d ${cfg.dataDir}/db/users 0700 root root -"
          "d /etc/wireguard 0700 root root -"
        ];

        systemd.services.wireguard-ui-db = {
          description = "Materialize SOPS-backed WireGuard UI database state";
          wantedBy = [ "multi-user.target" ];
          requires = [ "sops-nix.service" ];
          after = [ "sops-nix.service" ];
          before = [ "wireguard-ui.service" ];
          path = with pkgs; [
            coreutils
            jq
            wireguard-tools
          ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            set -eu
            umask 077

            install -d -m 0700 '${cfg.dataDir}/db/server' '${cfg.dataDir}/db/users' /etc/wireguard

            private_key="$(tr -d '\n' < '${config.sops.secrets.${privateKeySecret}.path}')"
            public_key="$(printf '%s' "$private_key" | wg pubkey)"
            admin_password_hash="$(tr -d '\n' < '${config.sops.secrets.${adminPasswordHashSecret}.path}')"

            jq -n \
              --arg private_key "$private_key" \
              --arg public_key "$public_key" \
              '{ private_key: $private_key, public_key: $public_key, updated_at: "1970-01-01T00:00:00Z" }' \
              > '${cfg.dataDir}/db/server/keypair.json'

            jq -n \
              --arg password_hash "$admin_password_hash" \
              '{ username: "admin", password: "", password_hash: $password_hash, admin: true }' \
              > '${cfg.dataDir}/db/users/admin.json'

            install -m 0600 '${globalSettings}' '${cfg.dataDir}/db/server/global_settings.json'
            install -m 0600 '${hashes}' '${cfg.dataDir}/db/server/hashes.json'
            install -m 0600 '${interfaces}' '${cfg.dataDir}/db/server/interfaces.json'
          '';
        };

        systemd.services.wireguard-ui = {
          description = "WireGuard UI";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          requires = [ "wireguard-ui-db.service" ];
          after = [
            "network-online.target"
            "wireguard-ui-db.service"
          ];
          path = with pkgs; [
            iproute2
            iptables
            wireguard-tools
          ];
          serviceConfig = {
            WorkingDirectory = cfg.dataDir;
            ExecStart = "${pkgs.wireguard-ui}/bin/wireguard-ui -bind-address ${cfg.bindAddress}";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
      }
    )
  ];
}
