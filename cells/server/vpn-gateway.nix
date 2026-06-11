{ config, ... }:
let
  userName = config.my.user.name;
in
{
  config.my.branches.vpn.nixosModules = [
    (
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        nordvpnPkg = pkgs.callPackage ../../pkgs/nordvpn { };
        useLocalDns =
          (lib.attrByPath [ "services" "pihole-ftl" "enable" ] false config)
          && (lib.attrByPath [ "services" "unbound" "enable" ] false config);
      in
      {
        nixpkgs.config.allowUnfree = true;

        environment.systemPackages = with pkgs; [
          nordvpnPkg
          wireguard-tools
        ];

        users = {
          groups.nordvpn = { };
          users.${userName}.extraGroups = [ "nordvpn" ];
        };

        systemd = {
          sockets.nordvpnd = {
            description = "NordVPN Daemon Socket";
            wantedBy = [ "sockets.target" ];
            partOf = [ "nordvpnd.service" ];
            socketConfig = {
              ListenStream = "/run/nordvpn/nordvpnd.sock";
              SocketGroup = "nordvpn";
              SocketMode = "0770";
              DirectoryMode = "0750";
            };
          };

          services.nordvpnd = {
            description = "NordVPN Daemon";
            wantedBy = [ "multi-user.target" ];
            requires = [ "nordvpnd.socket" ];
            after = [ "network-pre.target" ];
            path = with pkgs; [
              iptables
              iproute2
              procps
            ];
            serviceConfig = {
              ExecStart = "${nordvpnPkg}/bin/nordvpnd";
              NonBlocking = true;
              KillMode = "process";
              Restart = "on-failure";
              RestartSec = 5;
              RuntimeDirectory = "nordvpn";
              RuntimeDirectoryMode = "0750";
              Group = "nordvpn";
            };
          };

          tmpfiles.rules = [
            "d /usr/lib 0755 root root -"
            "L+ /usr/lib/nordvpn - - - - ${nordvpnPkg}/lib/nordvpn"
            "d /run/nordvpn 0770 root nordvpn"
            "d /var/lib/nordvpn 0750 root nordvpn"
            "d /var/lib/nordvpn/data 0750 root nordvpn"
          ];
        };

        systemd.services.nordvpn-gateway = {
          description = "Configure NordVPN client";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [
            "network-online.target"
            "nordvpnd.service"
          ]
          ++ lib.optionals useLocalDns [
            "pihole-ftl.service"
            "unbound.service"
          ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            Environment = "HOME=/root";
          };
          path = with pkgs; [
            coreutils
            nordvpnPkg
          ];
          script = ''
            set -eu

            optional() {
              "$@" || true
            }

            require() {
              "$@"
            }

            for _ in $(seq 1 30); do
              if nordvpn status >/dev/null 2>&1; then
                break
              fi
              sleep 1
            done

            require nordvpn set technology NORDLYNX
            optional nordvpn set lan-discovery enabled
            ${
              if useLocalDns then
                ''
                  require nordvpn set dns disabled
                ''
              else
                ''
                  require nordvpn set dns disabled
                ''
            }
            optional nordvpn set analytics disabled
            optional nordvpn set threatprotectionlite disabled
            ${
              if useLocalDns then
                ''
                  # Keep host management and local DNS stable while NordVPN is active.
                  require nordvpn set routing disabled
                ''
              else
                ''
                  require nordvpn set routing enabled
                ''
            }
            require nordvpn set autoconnect enabled
            # Keep NordVPN firewall features off; NixOS firewall stays authoritative.
            optional nordvpn set firewall disabled
            optional nordvpn set killswitch disabled
            require nordvpn connect
          '';
        };
      }
    )
  ];
}
