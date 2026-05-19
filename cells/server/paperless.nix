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
        paperless = config.services.paperless;
      in
      {
        services.paperless = {
          enable = true;
          address = "0.0.0.0";
          port = paperlessPort;

          database.createLocally = true;
          configureTika = true;

          settings = {
            PAPERLESS_OCR_LANGUAGE = "deu+eng";
            PAPERLESS_OCR_USER_ARGS = {
              optimize = 1;
              pdfa_image_compression = "lossless";
            };
            PAPERLESS_FILENAME_FORMAT = "{created_year}/{correspondent}/{title}";
            PAPERLESS_CONSUMER_RECURSIVE = true;
            PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS = true;
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
            SERVER_ADDRESS = "0.0.0.0";
            SERVER_PORT = stirlingPort;
            SYSTEM_DEFAULTLOCALE = "de-DE";
            METRICS_ENABLED = false;
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
          encryption.mode = "none";
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

        networking.firewall.allowedTCPPorts = [
          paperlessPort
          stirlingPort
        ];

        systemd.tmpfiles.rules = [
          "d ${backupScratchDir} 0700 root root - -"
          "d ${borgRepo} 0700 root root - -"
        ];

        systemd.services.paperless-task-queue.serviceConfig = {
          # ESPRIMO Q556 is small; keep imports/OCR usable without letting workers
          # fan out aggressively when multiple PDFs arrive at once.
          CPUQuota = lib.mkDefault "300%";
        };
      }
    )
  ];
}
