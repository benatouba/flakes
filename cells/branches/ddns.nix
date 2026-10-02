{ config, myHostLib, ... }:
let
  cfg = config.my.ddns;
in
{
  config.my.branches.ddns = {
    description = "Dynamic DNS updates via a curl script (deSEC).";
    needs = [ "secrets" ];
    nixosModules = [
      (
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          # Unit, user, group and state dir share this name. Renamed from
          # "ddclient"; the old /var/lib/ddclient state (cached IP) is orphaned and
          # may be deleted. Roll back by reverting the commit; the first run after
          # either direction re-pushes the IP.
          svcName = "ddns-update";
          curl = "${pkgs.curl}/bin/curl";

          # deSEC deletes a record type when the corresponding parameter is sent
          # empty, and leaves it untouched when sent `preserve`. Deleting is the
          # right default for AAAA here: see my.ddns.manageIpv6.
          ipv6Param = if cfg.manageIpv6 then "preserve" else "";

          updateScript = pkgs.writeShellScript "desec-ddns-update" ''
            set -euo pipefail

            hostname=${lib.escapeShellArg cfg.hostname}
            token=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.desec_ddns_token.path})

            # Advisory only. deSEC falls back to the connection source address
            # when myipv4 is omitted, so a failure here must not abort the update.
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

            # Force IPv4 so deSEC observes an IPv4 connection, otherwise omitting
            # myipv4 over an IPv6 connection would delete the A record.
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

            # The old GoDaddy updater used `curl -sf` and died with a bare exit 22,
            # which hid the reason for months. Always surface status and body.
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
          options.my.ddns.enable = myHostLib.mkDefaultOnEnable {
            inherit lib;
            description = "deSEC dynamic DNS updates";
          };

          config = lib.mkIf config.my.ddns.enable {
            assertions = [
              {
                assertion = cfg.hostname != "";
                message = "The ddns branch requires my.ddns.hostname to be set to a deSEC dynDNS hostname.";
              }
            ];

            users.users.${svcName} = {
              isSystemUser = true;
              group = svcName;
            };
            users.groups.${svcName} = { };

            sops.secrets.desec_ddns_token = {
              sopsFile = config.sops.defaultSopsFile;
              owner = svcName;
              mode = "0400";
            };

            systemd.services.${svcName} = {
              description = "Dynamic DNS updater (deSEC)";
              after = [ "network-online.target" ];
              wants = [ "network-online.target" ];
              serviceConfig = {
                Type = "oneshot";
                User = svcName;
                Group = svcName;
                StateDirectory = svcName;
                RuntimeDirectory = svcName;
                RuntimeDirectoryMode = "0700";
                ExecStart = "${updateScript}";

                # Needs only outbound HTTPS, its own state dir and the sops token.
                NoNewPrivileges = true;
                PrivateTmp = true;
                PrivateDevices = true;
                ProtectSystem = "strict";
                ProtectHome = true;
                ProtectKernelTunables = true;
                ProtectKernelModules = true;
                ProtectControlGroups = true;
                RestrictAddressFamilies = [
                  "AF_INET"
                  "AF_INET6"
                  "AF_UNIX"
                ];
                RestrictNamespaces = true;
                LockPersonality = true;
                CapabilityBoundingSet = "";
                SystemCallArchitectures = "native";
              };
            };

            systemd.timers.${svcName} = {
              description = "Run the deSEC DDNS update periodically";
              wantedBy = [ "timers.target" ];
              timerConfig = {
                OnBootSec = "2min";
                OnUnitActiveSec = cfg.interval;
                RandomizedDelaySec = "30s";
              };
            };
          };
        }
      )
    ];
  };
}
