{ lib, ... }:
let
  backupScratchDir = "/var/backup/paperless-office";
  borgRepo = "/var/backup/borg/paperless-office";
  paperlessPort = 28981;
  stirlingPort = 8080;
in
{
  config.my.branches.paperless.nixosModules = [
    (
      { config, ... }:
      let
        hasSops = config ? sops;
        paperless = config.services.paperless;
      in
      {
        assertions = [
          {
            assertion = hasSops;
            message = "Paperless backup encryption requires the secrets branch (sops-nix).";
          }
        ];

        sops.secrets.paperless_borg_passphrase = {
          sopsFile = config.sops.defaultSopsFile;
          owner = "root";
          mode = "0400";
        };

        services.paperless = {
          enable = true;
          address = "127.0.0.1";
          port = paperlessPort;

          database.createLocally = true;
          configureTika = true;

          settings = {
            PAPERLESS_OCR_LANGUAGE = "deu+eng";
            PAPERLESS_OCR_USER_ARGS = {
              optimize = 1;
              pdfa_image_compression = "lossless";
            };
            PAPERLESS_FILENAME_FORMAT = "{{ created_year }}/{{ correspondent }}/{{ title }}";
            PAPERLESS_CONSUMER_RECURSIVE = true;
            PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS = true;
            PAPERLESS_URL = "http://paperless.esprimo";
            PAPERLESS_ALLOWED_HOSTS = "paperless.esprimo,esprimo,127.0.0.1,localhost,192.168.188.197";
            PAPERLESS_CSRF_TRUSTED_ORIGINS = "http://paperless.esprimo,http://esprimo";
          };

          exporter = {
            enable = true;
            directory = "${config.services.paperless.dataDir}/export";
            onCalendar = "03:30:00";
          };
        };

        services.stirling-pdf = {
          enable = true;
          environment = {
            SERVER_ADDRESS = "127.0.0.1";
            SERVER_PORT = stirlingPort;
            SYSTEM_DEFAULTLOCALE = "de-DE";
            METRICS_ENABLED = false;
          };
        };

        services.caddy = {
          enable = true;
          virtualHosts = {
            "http://paperless.esprimo".extraConfig = ''
              encode zstd gzip
              @lan remote_ip private_ranges
              handle @lan {
                reverse_proxy 127.0.0.1:${toString paperlessPort}
              }
              respond 403
            '';
            "http://esprimo".extraConfig = ''
              encode zstd gzip
              @lan remote_ip private_ranges
              handle @lan {
                reverse_proxy 127.0.0.1:${toString paperlessPort}
              }
              respond 403
            '';
            "http://stirling.esprimo".extraConfig = ''
              encode zstd gzip
              @lan remote_ip private_ranges
              handle @lan {
                reverse_proxy 127.0.0.1:${toString stirlingPort}
              }
              respond 403
            '';
          };
        };

        services.syncthing = {
          enable = true;
          user = paperless.user;
          group = config.users.users.${paperless.user}.group;
          dataDir = "${paperless.dataDir}/syncthing";
          configDir = "${paperless.dataDir}/syncthing/.config/syncthing";
          guiAddress = "127.0.0.1:8384";
          openDefaultPorts = true;
          overrideDevices = false;
          overrideFolders = false;
          settings = {
            options = {
              localAnnounceEnabled = true;
              urAccepted = -1;
            };
            folders.paperless-consume = {
              id = "paperless-consume";
              label = "Paperless consume";
              path = paperless.consumptionDir;
              type = "sendreceive";
              devices = [ ];
            };
          };
        };

        services.borgbackup.jobs.paperless-office = {
          paths = [
            paperless.dataDir
            backupScratchDir
          ];
          exclude = [
            "${paperless.dataDir}/export"
            "${paperless.dataDir}/syncthing/.config/syncthing/index-*"
          ];
          repo = borgRepo;
          encryption = {
            mode = "repokey-blake2";
            passCommand = "cat ${config.sops.secrets.paperless_borg_passphrase.path}";
          };
          compression = "auto,zstd";
          startAt = "daily";
          persistentTimer = true;
          readWritePaths = [ backupScratchDir ];
          prune.keep = {
            daily = 7;
            weekly = 4;
            monthly = 6;
          };
          preHook = ''
            mkdir -p ${backupScratchDir}
            ${config.security.wrapperDir}/sudo -u ${paperless.user} \
              ${config.services.postgresql.package}/bin/pg_dump --dbname=paperless \
              > ${backupScratchDir}/paperless.sql
          '';
        };

        systemd.tmpfiles.rules = [
          "d ${backupScratchDir} 0700 root root - -"
          "d ${borgRepo} 0700 root root - -"
        ];

        systemd.services.paperless-task-queue.serviceConfig = {
          # ESPRIMO Q556 is small; keep imports/OCR usable without letting workers
          # fan out aggressively when multiple PDFs arrive at once.
          CPUQuota = lib.mkDefault "300%";
        };

        systemd.services.paperless-scheduler.preStart = lib.mkAfter ''
          ${paperless.package}/bin/paperless-ngx shell -c '
          from paperless.models import ApplicationConfiguration

          config = ApplicationConfiguration.objects.all().first()
          if config is None:
              config = ApplicationConfiguration.objects.create()

          config.language = "deu+eng"
          config.output_type = "pdfa"
          config.save(update_fields=["language", "output_type"])
          '
        '';

        systemd.services.gotenberg.environment = {
          OTEL_SDK_DISABLED = "true";
          OTEL_METRICS_EXPORTER = "none";
          OTEL_TRACES_EXPORTER = "none";
        };
      }
    )
  ];
}
