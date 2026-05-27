{ config, ... }:
let
  cfg = config.my.wger;
  userName = config.my.user.name;
  userEmail = config.my.user.email;
in
{
  config.my.branches.wger.nixosModules = [
    (
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        hasSops = config ? sops;

        dataDir = toString cfg.dataDir;
        dbUser = "wger";
        dbName = "wger";

        dbDataDir = "${dataDir}/postgres";
        redisDataDir = "${dataDir}/redis";
        mediaDir = "${dataDir}/media";
        staticDir = "${dataDir}/static";
        beatDir = "${dataDir}/celery-beat";
        backupDir = "${dataDir}/backup";
        publicDomain = if cfg.public.domain != "" then cfg.public.domain else cfg.domain;

        containerNames = [
          "wger-db"
          "wger-cache"
          "wger-web"
          "wger-nginx"
          "wger-celery-worker"
          "wger-celery-beat"
        ];

        containerUnits = map (name: "docker-${name}") containerNames;
        containerServiceUnits = map (unit: "${unit}.service") containerUnits;
        imagePullPolicy = "missing";
        containerServiceDefaults = {
          unitConfig = {
            StartLimitBurst = 10;
            StartLimitIntervalSec = 300;
          };
          serviceConfig = {
            Restart = "on-failure";
            RestartSec = "10s";
          };
        };

        maxDumpFiles = cfg.backup.keep.daily + cfg.backup.keep.weekly + cfg.backup.keep.monthly;

        customSettingsDir = pkgs.runCommand "wger-custom-settings" { } ''
          mkdir -p "$out/wger_adminapproval"

          cat > "$out/wger_adminapproval/__init__.py" <<'PY'
          default_app_config = "wger_adminapproval.apps.AdminApprovalConfig"
          PY

          cat > "$out/wger_adminapproval/settings.py" <<'PY'
          from settings.main import *  # noqa: F401,F403

          import os

          INSTALLED_APPS = list(INSTALLED_APPS)  # noqa: F405
          approval_app = "wger_adminapproval.apps.AdminApprovalConfig"
          if "wger_adminapproval" in INSTALLED_APPS:
              INSTALLED_APPS.remove("wger_adminapproval")
          if approval_app not in INSTALLED_APPS:
              INSTALLED_APPS.append(approval_app)

          MIDDLEWARE = list(MIDDLEWARE)  # noqa: F405
          approval_middleware = "wger_adminapproval.middleware.AdminApprovalMiddleware"
          if os.environ.get("WGER_REQUIRE_ADMIN_APPROVAL", "").lower() in {"1", "true", "yes", "on"}:
              if approval_middleware not in MIDDLEWARE:
                  try:
                      messages_index = MIDDLEWARE.index("django.contrib.messages.middleware.MessageMiddleware")
                  except ValueError:
                      MIDDLEWARE.append(approval_middleware)
                  else:
                      MIDDLEWARE.insert(messages_index + 1, approval_middleware)
          PY

          cat > "$out/wger_adminapproval/apps.py" <<'PY'
          import os
          from datetime import timedelta

          from django.apps import AppConfig, apps
          from django.db.models.signals import post_save
          from django.utils import timezone


          def _enabled(value):
              return str(value or "").lower() in {"1", "true", "yes", "on"}


          class AdminApprovalConfig(AppConfig):
              default_auto_field = "django.db.models.BigAutoField"
              name = "wger_adminapproval"

              def ready(self):
                  self._patch_routine_duration()
                  if _enabled(os.environ.get("WGER_REQUIRE_ADMIN_APPROVAL")):
                      self._connect_admin_approval()

              def _patch_routine_duration(self):
                  value = os.environ.get("WGER_MAX_ROUTINE_DURATION_DAYS")
                  if not value:
                      return
                  try:
                      max_days = int(value)
                  except ValueError:
                      return
                  if max_days <= 0:
                      return

                  Routine = apps.get_model("manager", "Routine")
                  Routine.MAX_DURATION_DAYS = max_days

              def _connect_admin_approval(self):
                  from allauth.account.models import EmailAddress
                  from django.contrib.auth import get_user_model
                  from rest_framework.authtoken.models import Token

                  User = get_user_model()

                  def deactivate_recent_user(user):
                      if user.is_staff or user.is_superuser or not user.is_active:
                          return

                      if timezone.now() - user.date_joined > timedelta(minutes=10):
                          return

                      User.objects.filter(
                          pk=user.pk,
                          is_active=True,
                          is_staff=False,
                          is_superuser=False,
                      ).update(is_active=False)
                      Token.objects.filter(user_id=user.pk).delete()

                  def deactivate_new_registered_account(sender, instance, created, **kwargs):
                      if not created or not instance.user_id:
                          return

                      deactivate_recent_user(instance.user)

                  def deactivate_new_api_token(sender, instance, created, **kwargs):
                      if not created or not instance.user_id:
                          return

                      deactivate_recent_user(instance.user)

                  post_save.connect(
                      deactivate_new_registered_account,
                      sender=EmailAddress,
                      dispatch_uid="wger_adminapproval.deactivate_new_registered_account",
                  )
                  post_save.connect(
                      deactivate_new_api_token,
                      sender=Token,
                      dispatch_uid="wger_adminapproval.deactivate_new_api_token",
                  )
          PY

          cat > "$out/wger_adminapproval/middleware.py" <<'PY'
          from django.conf import settings
          from django.contrib import messages
          from django.contrib.auth import logout
          from django.shortcuts import redirect


          class AdminApprovalMiddleware:
              def __init__(self, get_response):
                  self.get_response = get_response

              def __call__(self, request):
                  user = getattr(request, "user", None)
                  if user is not None and user.is_authenticated and not user.is_active:
                      logout(request)
                      messages.warning(
                          request,
                          "Your account is waiting for administrator approval.",
                      )
                      return redirect(settings.LOGIN_URL)

                  return self.get_response(request)
          PY
        '';

        nginxConfig = pkgs.writeText "wger-nginx.conf" ''
          map $http_x_forwarded_proto $wger_forwarded_proto {
            default $http_x_forwarded_proto;
            "" $scheme;
          }

          server {
            listen 8080;
            server_name ${cfg.domain} _;

            location /static/ {
              alias /wger/static/;
            }

            location /media/ {
              alias /wger/media/;
            }

            location / {
              resolver 127.0.0.11 ipv6=off valid=30s;
              set $wger_upstream http://web:8000;
              proxy_pass $wger_upstream;
              proxy_set_header Host $host;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Host $host;
              proxy_set_header X-Forwarded-Proto $wger_forwarded_proto;
            }
          }
        '';

        dockerNetworkScript = pkgs.writeShellScript "wger-create-network" ''
          set -euo pipefail

          if ! ${pkgs.docker}/bin/docker network inspect wger-net >/dev/null 2>&1; then
            ${pkgs.docker}/bin/docker network create wger-net >/dev/null
          fi
        '';

        pgDumpScript = pkgs.writeShellScript "wger-db-dump" ''
          set -euo pipefail

          stamp="$(${pkgs.coreutils}/bin/date +%Y%m%d-%H%M%S)"
          dumpFile="${backupDir}/wger-''${stamp}.sql.gz"

          ${pkgs.coreutils}/bin/mkdir -p ${backupDir}
          ${pkgs.docker}/bin/docker exec wger-db pg_dump -U ${dbUser} -d ${dbName} \
            | ${pkgs.gzip}/bin/gzip -c > "$dumpFile"
          ${pkgs.coreutils}/bin/chmod 0600 "$dumpFile"

          mapfile -t dumps < <(
            ${pkgs.findutils}/bin/find ${backupDir} -mindepth 1 -maxdepth 1 -type f -name 'wger-*.sql.gz' -printf '%T@ %p\n' \
              | ${pkgs.coreutils}/bin/sort -nr \
              | ${pkgs.gawk}/bin/awk '{$1=""; sub(/^ /, ""); print}'
          )

          if [ "''${#dumps[@]}" -gt ${toString maxDumpFiles} ]; then
            for file in "''${dumps[@]:${toString maxDumpFiles}}"; do
              ${pkgs.coreutils}/bin/rm -f -- "$file"
            done
          fi
        '';

        dbPasswordSyncScript = pkgs.writeShellScript "wger-sync-db-password" ''
          set -euo pipefail

          password="$(${pkgs.gnugrep}/bin/grep '^DJANGO_DB_PASSWORD=' ${
            config.sops.templates."wger-prod.env".path
          } | ${pkgs.coreutils}/bin/cut -d= -f2-)"

          for attempt in $(${pkgs.coreutils}/bin/seq 1 60); do
            if ${pkgs.docker}/bin/docker exec wger-db pg_isready -U ${dbUser} -d ${dbName} >/dev/null 2>&1; then
              break
            fi

            if [ "$attempt" -eq 60 ]; then
              echo "Wger PostgreSQL did not become ready in time" >&2
              exit 1
            fi

            ${pkgs.coreutils}/bin/sleep 2
          done

          ${pkgs.docker}/bin/docker exec -i wger-db psql -U ${dbUser} -d postgres \
            -v password="$password" >/dev/null <<'SQL'
          ALTER USER ${dbUser} WITH PASSWORD :'password';
          SQL
        '';
      in
      lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            assertions = [
              {
                assertion = hasSops;
                message = "Wger requires the secrets branch (sops-nix) to be enabled.";
              }
            ];
          }

          (lib.mkIf hasSops {
            virtualisation.docker.enable = true;
            users.users.${userName}.extraGroups = lib.mkAfter [ "docker" ];

            virtualisation.oci-containers = {
              backend = "docker";
              containers = {
                wger-db = {
                  image = "docker.io/postgres:${cfg.postgresPackage}";
                  pull = imagePullPolicy;
                  environment = {
                    POSTGRES_USER = dbUser;
                    POSTGRES_DB = dbName;
                    TZ = cfg.timezone;
                  };
                  environmentFiles = [ config.sops.templates."wger-prod.env".path ];
                  volumes = [ "${dbDataDir}:/var/lib/postgresql/data" ];
                  capabilities = {
                    CAP_CHOWN = true;
                    CAP_DAC_OVERRIDE = true;
                    CAP_FOWNER = true;
                    CAP_SETGID = true;
                    CAP_SETUID = true;
                  };
                  extraOptions = [
                    "--network=wger-net"
                    "--network-alias=db"
                    "--health-cmd=pg_isready -U ${dbUser}"
                    "--health-interval=10s"
                    "--health-timeout=5s"
                    "--health-retries=5"
                    "--security-opt=no-new-privileges:true"
                  ];
                  autoStart = true;
                };

                wger-cache = {
                  image = "docker.io/redis:${cfg.redisPackage}";
                  pull = imagePullPolicy;
                  volumes = [ "${redisDataDir}:/data" ];
                  cmd = [
                    "redis-server"
                    "--appendonly"
                    "yes"
                  ];
                  extraOptions = [
                    "--network=wger-net"
                    "--network-alias=cache"
                    "--health-cmd=redis-cli ping"
                    "--health-interval=10s"
                    "--health-timeout=5s"
                    "--health-retries=5"
                    "--security-opt=no-new-privileges:true"
                    "--read-only"
                    "--tmpfs=/tmp"
                  ];
                  autoStart = true;
                };

                wger-web = {
                  image = "docker.io/wger/server:${cfg.package}";
                  pull = imagePullPolicy;
                  dependsOn = [
                    "wger-db"
                    "wger-cache"
                  ];
                  environment = {
                    DJANGO_SETTINGS_MODULE = "wger_adminapproval.settings";
                    PYTHONPATH = "/home/wger/custom";
                    WGER_REQUIRE_ADMIN_APPROVAL = lib.boolToString cfg.registration.requireAdminApproval;
                    WGER_MAX_ROUTINE_DURATION_DAYS = toString cfg.routine.maxDurationDays;
                  };
                  environmentFiles = [ config.sops.templates."wger-prod.env".path ];
                  volumes = [
                    "${customSettingsDir}:/home/wger/custom:ro"
                    "${mediaDir}:/home/wger/media"
                    "${staticDir}:/home/wger/static"
                  ];
                  extraOptions = [
                    "--network=wger-net"
                    "--network-alias=web"
                    "--security-opt=no-new-privileges:true"
                    "--tmpfs=/tmp"
                  ];
                  autoStart = true;
                };

                wger-nginx = {
                  image = "docker.io/nginx:${cfg.nginxPackage}";
                  pull = imagePullPolicy;
                  dependsOn = [ "wger-web" ];
                  volumes = [
                    "${staticDir}:/wger/static:ro"
                    "${mediaDir}:/wger/media:ro"
                    "${nginxConfig}:/etc/nginx/conf.d/default.conf:ro"
                  ];
                  ports = [ "127.0.0.1:${toString cfg.port}:8080" ];
                  extraOptions = [
                    "--network=wger-net"
                    "--network-alias=nginx"
                    "--security-opt=no-new-privileges:true"
                    "--tmpfs=/var/cache/nginx"
                    "--tmpfs=/var/run"
                  ];
                  autoStart = true;
                };

                wger-celery-worker = {
                  image = "docker.io/wger/server:${cfg.package}";
                  pull = imagePullPolicy;
                  cmd = [ "/start-worker" ];
                  dependsOn = [ "wger-web" ];
                  environment = {
                    DJANGO_SETTINGS_MODULE = "wger_adminapproval.settings";
                    PYTHONPATH = "/home/wger/custom";
                    WGER_REQUIRE_ADMIN_APPROVAL = lib.boolToString cfg.registration.requireAdminApproval;
                    WGER_MAX_ROUTINE_DURATION_DAYS = toString cfg.routine.maxDurationDays;
                  };
                  environmentFiles = [ config.sops.templates."wger-prod.env".path ];
                  volumes = [
                    "${customSettingsDir}:/home/wger/custom:ro"
                    "${mediaDir}:/home/wger/media"
                  ];
                  extraOptions = [
                    "--network=wger-net"
                    "--security-opt=no-new-privileges:true"
                    "--tmpfs=/tmp"
                  ];
                  autoStart = true;
                };

                wger-celery-beat = {
                  image = "docker.io/wger/server:${cfg.package}";
                  pull = imagePullPolicy;
                  cmd = [ "/start-beat" ];
                  dependsOn = [ "wger-celery-worker" ];
                  environment = {
                    DJANGO_SETTINGS_MODULE = "wger_adminapproval.settings";
                    PYTHONPATH = "/home/wger/custom";
                    WGER_REQUIRE_ADMIN_APPROVAL = lib.boolToString cfg.registration.requireAdminApproval;
                    WGER_MAX_ROUTINE_DURATION_DAYS = toString cfg.routine.maxDurationDays;
                  };
                  environmentFiles = [ config.sops.templates."wger-prod.env".path ];
                  volumes = [
                    "${customSettingsDir}:/home/wger/custom:ro"
                    "${beatDir}:/home/wger/beat"
                  ];
                  extraOptions = [
                    "--network=wger-net"
                    "--security-opt=no-new-privileges:true"
                    "--tmpfs=/tmp"
                  ];
                  autoStart = true;
                };
              };
            };

            systemd.services =
              (lib.genAttrs containerUnits (
                _:
                containerServiceDefaults
                // {
                  after = [ "wger-docker-network.service" ];
                  requires = [ "wger-docker-network.service" ];
                }
              ))
              // {
                docker-wger-web = containerServiceDefaults // {
                  after = [
                    "wger-docker-network.service"
                    "wger-db-password-sync.service"
                  ];
                  requires = [
                    "wger-docker-network.service"
                    "wger-db-password-sync.service"
                  ];
                };

                docker-wger-celery-worker = containerServiceDefaults // {
                  after = [
                    "wger-docker-network.service"
                    "wger-db-password-sync.service"
                  ];
                  requires = [
                    "wger-docker-network.service"
                    "wger-db-password-sync.service"
                  ];
                };

                docker-wger-celery-beat = containerServiceDefaults // {
                  after = [
                    "wger-docker-network.service"
                    "wger-db-password-sync.service"
                  ];
                  requires = [
                    "wger-docker-network.service"
                    "wger-db-password-sync.service"
                  ];
                };

                docker-wger-nginx = containerServiceDefaults // {
                  after = [
                    "wger-docker-network.service"
                    "docker-wger-web.service"
                  ];
                  requires = [
                    "wger-docker-network.service"
                    "docker-wger-web.service"
                  ];
                };
              }
              // {
                wger-docker-network = {
                  description = "Create docker network for Wger containers";
                  before = containerServiceUnits;
                  after = [ "docker.service" ];
                  requires = [ "docker.service" ];
                  serviceConfig = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                    ExecStart = dockerNetworkScript;
                  };
                };

                wger-db-password-sync = {
                  description = "Synchronize Wger PostgreSQL password from SOPS";
                  after = [
                    "wger-docker-network.service"
                    "docker-wger-db.service"
                  ];
                  requires = [
                    "wger-docker-network.service"
                    "docker-wger-db.service"
                  ];
                  before = [
                    "docker-wger-web.service"
                    "docker-wger-celery-worker.service"
                    "docker-wger-celery-beat.service"
                    "docker-wger-nginx.service"
                  ];
                  serviceConfig = {
                    Type = "oneshot";
                    ExecStart = dbPasswordSyncScript;
                  };
                };
              }
              // (lib.optionalAttrs cfg.backup.enable {
                wger-db-backup = {
                  description = "Backup Wger PostgreSQL database";
                  after = [ "docker-wger-db.service" ];
                  requires = [ "docker-wger-db.service" ];
                  serviceConfig = {
                    Type = "oneshot";
                    ExecStart = pgDumpScript;
                  };
                };
              });

            systemd.tmpfiles.rules = [
              "d ${dataDir} 0750 root root - -"
              "d ${dbDataDir} 0750 root root - -"
              "d ${redisDataDir} 0750 root root - -"
              "d ${mediaDir} 0775 1000 1000 - -"
              "d ${staticDir} 0775 1000 1000 - -"
              "d ${beatDir} 0770 1000 1000 - -"
              "d ${backupDir} 0700 root root - -"
            ];

            sops.secrets.wger_secret_key = {
              sopsFile = config.sops.defaultSopsFile;
              owner = "root";
              mode = "0400";
              restartUnits = containerServiceUnits;
            };

            sops.secrets.wger_signing_key = {
              sopsFile = config.sops.defaultSopsFile;
              owner = "root";
              mode = "0400";
              restartUnits = containerServiceUnits;
            };

            sops.secrets.wger_db_password = {
              sopsFile = config.sops.defaultSopsFile;
              owner = "root";
              mode = "0400";
              restartUnits = containerServiceUnits;
            };

            sops.templates."wger-prod.env" = {
              owner = "root";
              mode = "0400";
              restartUnits = containerServiceUnits;
              content = ''
                SECRET_KEY=${config.sops.placeholder.wger_secret_key}
                SIGNING_KEY=${config.sops.placeholder.wger_signing_key}
                POSTGRES_PASSWORD=${config.sops.placeholder.wger_db_password}

                TIME_ZONE=${cfg.timezone}
                TZ=${cfg.timezone}

                SITE_URL=${cfg.siteUrl}
                CSRF_TRUSTED_ORIGINS=${lib.concatStringsSep "," ([ cfg.siteUrl ] ++ cfg.trustedOrigins)}
                WGER_PORT=8000
                X_FORWARDED_PROTO_HEADER_SET=True

                ALLOW_REGISTRATION=${lib.boolToString cfg.registration.allowRegistration}
                ALLOW_GUEST_USERS=${lib.boolToString cfg.registration.allowGuestUsers}
                ALLOW_UPLOAD_VIDEOS=false

                USE_CELERY=true
                CELERY_BROKER=redis://cache:6379/2
                CELERY_BACKEND=redis://cache:6379/2
                CELERY_WORKER_CONCURRENCY=2

                DJANGO_DB_ENGINE=django.db.backends.postgresql
                DJANGO_DB_DATABASE=${dbName}
                DJANGO_DB_USER=${dbUser}
                DJANGO_DB_PASSWORD=${config.sops.placeholder.wger_db_password}
                DJANGO_DB_HOST=db
                DJANGO_DB_PORT=5432
                DJANGO_PERFORM_MIGRATIONS=True

                DJANGO_CACHE_BACKEND=django_redis.cache.RedisCache
                DJANGO_CACHE_LOCATION=redis://cache:6379/1
                DJANGO_CACHE_TIMEOUT=1296000
                DJANGO_CACHE_CLIENT_CLASS=django_redis.client.DefaultClient

                AXES_ENABLED=True
                AXES_FAILURE_LIMIT=10
                AXES_COOLOFF_TIME=30
                AXES_HANDLER=axes.handlers.cache.AxesCacheHandler
                AXES_LOCKOUT_PARAMETERS=ip_address

                DJANGO_DEBUG=False
                WGER_USE_GUNICORN=True
                EXERCISE_CACHE_TTL=86400
              '';
            };

            services.caddy = lib.mkIf cfg.public.enable {
              enable = true;
              email = userEmail;

              virtualHosts.${publicDomain} = {
                extraConfig = ''
                  encode zstd gzip
                  header {
                    Strict-Transport-Security "max-age=31536000; includeSubDomains"
                    X-Content-Type-Options "nosniff"
                    X-Frame-Options "DENY"
                    Referrer-Policy "strict-origin-when-cross-origin"
                    Permissions-Policy "camera=(), microphone=(), geolocation=()"
                    -Server
                  }

                  request_body {
                    max_size 20MB
                  }

                  reverse_proxy 127.0.0.1:${toString cfg.port} {
                    header_up X-Forwarded-Proto https
                    header_up X-Forwarded-Host {host}
                    header_down -Server
                  }
                '';
              };
            };

            networking.firewall.allowedTCPPorts =
              if cfg.public.enable then
                [
                  80
                  443
                ]
              else
                [ cfg.port ];

            systemd.timers.wger-db-backup = lib.mkIf cfg.backup.enable {
              description = "Timer for Wger PostgreSQL backup";
              wantedBy = [ "timers.target" ];
              timerConfig = {
                OnCalendar = cfg.backup.schedule;
                Persistent = true;
                Unit = "wger-db-backup.service";
              };
            };
          })
        ]
      )
    )
  ];
}
