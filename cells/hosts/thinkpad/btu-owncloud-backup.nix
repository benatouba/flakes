{ lib, ... }:
{
  config.my.hosts.thinkpad.nixosModules = [
    {
      options.services.btu-owncloud-backup.enable = lib.mkEnableOption "encrypted backup to personal BTU ownCloud";
    }
  ];

  config.my.hosts.thinkpad.hmModules = [
    (
      {
        config,
        osConfig,
        pkgs,
        ...
      }:
      let
        inherit (config.home) homeDirectory;
        name = "btu-owncloud-backup";
        password = config.sops.secrets."${name}/repository-password".path;
        dav = config.sops.secrets."${name}/webdav-config".path;
        remote = "btu-personal:thinkpad-restic";
        maxBytes = 100000000;
        excludedPaths = [
          ".git"
          ".devenv"
          ".venv"
          "node_modules"
          "*.lock"
          "*.lockb"
          "package-lock.json"
          "npm-shrinkwrap.json"
          "pnpm-lock.yaml"
          "packages.lock.json"
        ];
        excludedRoots = [
          "${homeDirectory}/documents/education"
          "${homeDirectory}/projects/soga"
        ];
        findExclusions =
          lib.concatMapStringsSep " -o " (path: "-path ${lib.escapeShellArg "*/${path}"}") excludedPaths
          + " -o "
          + lib.concatMapStringsSep " -o " (path: "-path ${lib.escapeShellArg path}") excludedRoots;
        resticExclusions = lib.concatMapStringsSep " " (path: "--exclude ${lib.escapeShellArg path}") (
          excludedPaths ++ excludedRoots
        );
        rclone = pkgs.writeShellScript "btu-personal-rclone" ''
          exec ${pkgs.coreutils}/bin/env -i HOME=${lib.escapeShellArg homeDirectory} \
            SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
            ${lib.getExe pkgs.rclone} --config ${lib.escapeShellArg dav} \
            --webdav-owncloud-exclude-shares --webdav-owncloud-exclude-mounts "$@"
        '';
        backup = pkgs.writeShellApplication {
          inherit name;
          runtimeInputs = with pkgs; [
            coreutils
            findutils
            gawk
            jq
            python3
          ];
          text = ''
            umask 077
            fail() { echo "$*" >&2; exit 1; }
            sources=(${lib.escapeShellArg "${homeDirectory}/projects"} ${lib.escapeShellArg "${homeDirectory}/documents"})
            state=${lib.escapeShellArg "${homeDirectory}/.local/state/${name}"}
            if [[ ''${1:-} == disable-schedule ]]; then
              rm -f -- "$state/schedule-enabled"
              exit
            fi
            [[ -s ${lib.escapeShellArg password} && -s ${lib.escapeShellArg dav} ]] ||
              fail "Backup credentials unavailable; check sops-nix.service."

            # Accept only the personal BTU WebDAV endpoint and a dedicated config.
            python3 -I - ${lib.escapeShellArg dav} <<'PY'
            import configparser
            import re
            import sys
            from urllib.parse import unquote

            try:
                cfg = configparser.ConfigParser(interpolation=None)
                with open(sys.argv[1]) as f:
                    cfg.read_file(f)
                section = cfg["btu-personal"]
                assert cfg.sections() == ["btu-personal"] and not cfg.defaults()
                assert set(section) == {"type", "url", "vendor", "user", "pass"}
                assert section["type"] == "webdav" and section["vendor"] == "owncloud"
                match = re.fullmatch(
                    r"https://www\.b-tu\.de/owncloud/remote\.php/dav/files/((?:[A-Za-z0-9_.@-]|%[a-fA-F0-9]{2})+)/",
                    section["url"],
                )
                user = unquote(match[1]) if match else ""
                assert re.fullmatch(r"[A-Za-z0-9_@.-]+", user) and user not in {".", ".."}
                assert user == section["user"] and re.fullmatch(r"[A-Za-z0-9_-]{23,}", section["pass"])
            except (AssertionError, KeyError, ValueError, configparser.Error, OSError):
                sys.exit("Invalid personal BTU WebDAV configuration.")
            PY

            restic() {
              env -i HOME=${lib.escapeShellArg homeDirectory} \
                ${lib.getExe pkgs.restic} \
                --password-file ${lib.escapeShellArg password} \
                --repo rclone:${remote} -o rclone.program=${rclone} "$@"
            }
            check_sources() {
              for source in "''${sources[@]}"; do
                [[ -d "$source" && ! -L "$source" ]] || fail "Backup source missing or a symlink: $source"
              done
            }
            preflight() {
              check_sources
              # Conservative estimate before deduplication and compression.
              estimate=$(find -P "''${sources[@]}" \( ${findExclusions} \) -prune -o \
                -type f ! -size +${toString maxBytes}c -printf '%s\n' |
                awk '{ total += $1 } END { printf "%.0f\n", total }') ||
                fail "Could not scan all backup sources; repository was not initialized."
              free=$(${rclone} about btu-personal: --json | jq -er '.free | select(type == "number" and . >= 0)')
              printf 'Eligible file bytes: %s; ownCloud free bytes: %s\n' "$estimate" "$free"
              (( free >= estimate + 100000000 )) || fail "Insufficient space for the estimated initial backup and 100 MB headroom."
            }

            case "''${1:-}" in
              preflight) preflight ;;
              init)
                preflight
                ${rclone} mkdir ${remote}
                listing=$(${rclone} lsf ${remote})
                [[ -z "$listing" ]] || fail "Backup directory is not empty."
                restic init
                ;;
              backup)
                check_sources
                restic backup ${resticExclusions} --exclude-larger-than ${toString maxBytes} "''${sources[@]}"
                ;;
              snapshots|check)
                restic "$1"
                ;;
              restore)
                [[ $# == 2 ]] || fail "Usage: $0 restore SNAPSHOT"
                [[ "$2" == latest || "$2" =~ ^[a-f0-9]{8,64}$ ]] || fail "Expected latest or a snapshot ID."
                mkdir -p -- "$state"
                target=$(mktemp -d -- "$state/restore.XXXXXXXX")
                printf 'Restore target: %s\n' "$target"
                restic restore "$2" --target "$target" --verify
                ;;
              enable-schedule)
                restic snapshots --json | jq -e 'length > 0' >/dev/null
                mkdir -p -- "$state"
                touch "$state/schedule-enabled"
                ;;
              *) fail "Usage: $0 {preflight|init|backup|snapshots|check|restore SNAPSHOT|enable-schedule|disable-schedule}" ;;
            esac
          '';
        };
      in
      lib.mkIf osConfig.services.btu-owncloud-backup.enable {
        sops.secrets = {
          "${name}/repository-password".mode = "0400";
          "${name}/webdav-config".mode = "0400";
        };
        home.packages = [ backup ];

        systemd.user.services.${name} = {
          Unit = {
            Description = "Encrypted backup to personal BTU ownCloud";
            PartOf = [ "graphical-session.target" ];
            Requires = [ "sops-nix.service" ];
            After = [ "sops-nix.service" ];
            ConditionPathExists = "%h/.local/state/${name}/schedule-enabled";
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${lib.getExe backup} backup";
            UMask = "0077";
            TimeoutStartSec = "4h";
            # Restic diagnostics can include source filenames and WebDAV paths.
            StandardOutput = "null";
            StandardError = "null";
          };
        };
        systemd.user.timers.${name} = {
          Unit = {
            Description = "Daily personal BTU ownCloud backup";
            PartOf = [ "graphical-session.target" ];
          };
          Timer = {
            OnCalendar = "daily";
            Persistent = true;
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      }
    )
  ];
}
