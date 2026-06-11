_: {
  config.my.branches.ddns.nixosModules = [
    (
      {
        config,
        pkgs,
        ...
      }:
      let
        domain = "benrlschmidt.de";
        hostname = "workout";
        ttl = 600;
        godaddyApi = "api.godaddy.com";

        updateScript = pkgs.writeShellScript "godaddy-ddns-update" ''
          set -euo pipefail

          DOMAIN=${domain}
          HOSTNAME=${hostname}
          FQDN="$HOSTNAME.$DOMAIN"

          api_key=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.godaddy_ddns_api_key.path})
          api_secret=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.godaddy_ddns_api_secret.path})
          auth="Authorization: sso-key $api_key:$api_secret"

          public_ip=$(${pkgs.curl}/bin/curl -sf https://api.ipify.org)
          if [ -z "$public_ip" ]; then
            echo "ERROR: could not determine public IP" >&2
            exit 1
          fi

          current_ip=$(
            ${pkgs.curl}/bin/curl -sf \
              -H "$auth" \
              -H "Accept: application/json" \
              "https://${godaddyApi}/v1/domains/$DOMAIN/records/A/$HOSTNAME" \
            | ${pkgs.jq}/bin/jq -r '.[0].data // empty'
          )

          if [ "$current_ip" = "$public_ip" ]; then
            echo "$FQDN already points to $public_ip, no update needed"
            exit 0
          fi

          echo "updating $FQDN from ''${current_ip:-<none>} to $public_ip"
          ${pkgs.curl}/bin/curl -sf \
            -X PUT \
            -H "$auth" \
            -H "Content-Type: application/json" \
            "https://${godaddyApi}/v1/domains/$DOMAIN/records/A/$HOSTNAME" \
            -d "$(${pkgs.jq}/bin/jq -n --arg ip "$public_ip" --arg name "$HOSTNAME" --argjson ttl ${toString ttl} \
              '[{data: $ip, name: $name, type: "A", ttl: $ttl}]')"
          echo "updated $FQDN to $public_ip"
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
            ExecStart = "${updateScript}";
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
