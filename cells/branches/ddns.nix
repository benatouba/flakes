{ config, ... }:
let
  cfg = config.my.ddns;
in
{
  config.my.branches.ddns = {
    description = "Dynamic DNS updates via ddclient (deSEC).";
    nixosModules = [
      (
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          curl = "${pkgs.curl}/bin/curl";

          # deSEC deletes a record on empty param; default AAAA to delete here.
          ipv6Param = if cfg.manageIpv6 then "preserve" else "";

          updateScript = pkgs.writeShellScript "desec-ddns-update" ''
            set -euo pipefail

            hostname=${lib.escapeShellArg cfg.hostname}
            token=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.desec_ddns_token.path})

            # Advisory only; deSEC falls back to source address, so never abort here.
            public_ip=$(${curl} -4 -sf --max-time 10 ${lib.escapeShellArg cfg.ipEchoUrl} 2>/dev/null || true)
            public_ip=$(${pkgs.coreutils}/bin/tr -d '[:space:]' <<<"$public_ip")

            ip_args=()
            if [ -n "$public_ip" ]; then
              echo "publishing $hostname -> $public_ip"
              ip_args=(--data-urlencode "myipv4=$public_ip")
            else
              echo "WARNING: could not determine public IPv4 via ${cfg.ipEchoUrl};" \
                   "letting deSEC use the connection source address" >&2
            fi

            # Force IPv4, else omitting myipv4 over IPv6 deletes the A record.
            body=$(${pkgs.coreutils}/bin/mktemp)
            trap '${pkgs.coreutils}/bin/rm -f "$body"' EXIT

            status=$(${curl} -4 -sS --max-time 30 --get \
              -o "$body" -w '%{http_code}' \
              -H "Authorization: Token $token" \
              --data-urlencode "hostname=$hostname" \
              --data-urlencode "myipv6=${ipv6Param}" \
              "''${ip_args[@]}" \
              ${lib.escapeShellArg cfg.updateEndpoint}) || {
              echo "ERROR: deSEC update request failed to complete" >&2
              exit 1
            }

            response=$(${pkgs.coreutils}/bin/tr -d '\r\n' <"$body")

            # Always surface status+body; bare curl -sf hid failures for months.
            if [ "$status" != "200" ]; then
              echo "ERROR: deSEC returned HTTP $status: ''${response:-<empty body>}" >&2
              exit 1
            fi

            case "$response" in
              good* | nochg*)
                echo "deSEC accepted the update for $hostname: $response"
                ;;
              *)
                echo "ERROR: unexpected deSEC response for $hostname: ''${response:-<empty body>}" >&2
                exit 1
                ;;
            esac
          '';
        in
        {
          assertions = [
            {
              assertion = cfg.hostname != "";
              message = "The ddns branch requires my.ddns.hostname to be set to a deSEC dynDNS hostname.";
            }
          ];

          users.users.ddclient = {
            isSystemUser = true;
            group = "ddclient";
          };
          users.groups.ddclient = { };

          sops.secrets.desec_ddns_token = {
            sopsFile = config.sops.defaultSopsFile;
            owner = "ddclient";
            mode = "0400";
          };

          systemd.services.ddclient = {
            description = "Dynamic DNS client (deSEC)";
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
              OnUnitActiveSec = cfg.interval;
              RandomizedDelaySec = "30s";
            };
          };
        }
      )
    ];
  };
}
