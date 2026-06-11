_: {
  config.my.branches.ddns.nixosModules = [
    (
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        ddclientRun = pkgs.writeShellScript "ddclient-run" ''
          set -euo pipefail

          api_key=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.godaddy_ddns_api_key.path})
          api_secret=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.godaddy_ddns_api_secret.path})

          umask 077
          cat > "$RUNTIME_DIRECTORY/ddclient.conf" << EOF
          cache=$STATE_DIRECTORY/ddclient.cache
          foreground=YES
          use=web, web=checkip.dyndns.com/, web-skip='Current IP Address: '
          protocol=godaddy
          login=$api_key
          password=$api_secret
          zone=benrlschmidt.de
          ssl=yes
          wildcard=YES
          quiet=yes
          verbose=no
          ttl=600
          workout.benrlschmidt.de
          EOF

          exec ${lib.getExe pkgs.ddclient} -file "$RUNTIME_DIRECTORY/ddclient.conf"
        '';
      in
      {
        users.users.ddclient = {
          isSystemUser = true;
          group = "ddclient";
        };
        users.groups.ddclient = { };

        sops.secrets = {
          godaddy_ddns_api_key = {
            sopsFile = config.sops.defaultSopsFile;
            owner = "ddclient";
            mode = "0400";
          };
          godaddy_ddns_api_secret = {
            sopsFile = config.sops.defaultSopsFile;
            owner = "ddclient";
            mode = "0400";
          };
        };

        systemd.services.ddclient = {
          description = "Dynamic DNS client (GoDaddy)";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            User = "ddclient";
            Group = "ddclient";
            StateDirectory = "ddclient";
            RuntimeDirectory = "ddclient";
            RuntimeDirectoryMode = "0700";
            ExecStart = "${ddclientRun}";
          };
        };

        systemd.timers.ddclient = {
          description = "Run ddclient periodically";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "2min";
            OnUnitActiveSec = "5min";
            RandomizedDelaySec = "30s";
          };
        };
      }
    )
  ];
}
