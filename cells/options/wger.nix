{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.my.wger = {
    enable = mkEnableOption "self-hosted wger stack";

    domain = mkOption {
      type = types.str;
      default = "wger.example.com";
      description = "Public domain used for the Wger reverse proxy.";
    };

    siteUrl = mkOption {
      type = types.str;
      default = "http://wger.example.com";
      description = "Public URL used by Wger for absolute links and host checks.";
    };

    trustedOrigins = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional browser origins accepted by Wger's CSRF protection.";
    };

    package = mkOption {
      type = types.str;
      default = "2.6.0";
      description = "Container image tag for docker.io/wger/server. Pin an exact patch tag; the pull policy is `missing`, so mutable tags never re-pull.";
    };

    redisPackage = mkOption {
      type = types.str;
      default = "8-alpine";
      description = "Container image tag for docker.io/redis.";
    };

    postgresPackage = mkOption {
      type = types.str;
      default = "15-alpine";
      description = "Container image tag for docker.io/postgres.";
    };

    nginxPackage = mkOption {
      type = types.str;
      default = "1.30-alpine";
      description = "Container image tag for docker.io/nginx.";
    };

    port = mkOption {
      type = types.port;
      default = 8310;
      description = "Local host port that serves Wger over HTTP.";
    };

    public = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Expose Wger through the host Caddy reverse proxy with ACME TLS.";
      };

      domain = mkOption {
        type = types.str;
        default = "";
        description = "Public HTTPS domain for Wger.";
      };
    };

    timezone = mkOption {
      type = types.str;
      default = "Europe/Berlin";
      description = "Timezone exposed to Wger containers.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/wger";
      description = "State root for Wger database, cache, media, static assets, and backups.";
    };

    registration = {
      allowRegistration = mkOption {
        type = types.bool;
        default = false;
        description = "Allow public account registration.";
      };

      allowGuestUsers = mkOption {
        type = types.bool;
        default = false;
        description = "Allow guest mode users without an account.";
      };

      requireAdminApproval = mkOption {
        type = types.bool;
        default = false;
        description = "Deactivate newly registered users until an admin activates them.";
      };
    };

    routine = {
      maxDurationDays = mkOption {
        type = types.int;
        default = 120;
        description = "Maximum routine duration accepted by the local Wger instance.";
      };
    };

    jwt = {
      refreshTokenLifetimeHours = mkOption {
        type = types.int;
        default = 3000;
        description = "Lifetime of Wger JWT refresh tokens, in hours.";
      };
    };

    powersync = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable the PowerSync service for mobile app offline sync.";
      };

      package = mkOption {
        type = types.str;
        default = "1.23.3";
        description = "Container image tag for docker.io/journeyapps/powersync-service.";
      };

      compactSchedule = mkOption {
        type = types.str;
        default = "daily";
        description = "systemd calendar expression for the PowerSync bucket compaction timer.";
      };
    };

    backup = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable periodic PostgreSQL dump backups for Wger.";
      };

      schedule = mkOption {
        type = types.str;
        default = "daily";
        description = "systemd calendar expression for backup timer.";
      };

      keep = {
        daily = mkOption {
          type = types.int;
          default = 7;
          description = "Number of most recent database dumps to retain.";
        };

        weekly = mkOption {
          type = types.int;
          default = 4;
          description = "Number of distinct ISO weeks for which to retain the newest dump.";
        };

        monthly = mkOption {
          type = types.int;
          default = 6;
          description = "Number of distinct months for which to retain the newest dump.";
        };
      };
    };
  };
}
