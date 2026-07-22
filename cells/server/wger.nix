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

        brandingFeaturesTemplate = ./wger-features-bnsd.html;
        brandingTemplateFeatures = ./wger-template-features-bnsd.html;
        brandingHeroImage = ./wger-title-foto.jpg;

        containerNames = [
          "wger-db"
          "wger-cache"
          "wger-web"
          "wger-nginx"
          "wger-celery-worker"
          "wger-celery-beat"
        ]
        ++ lib.optional cfg.powersync.enable "wger-powersync";

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

            location /ps/ {
              resolver 127.0.0.11 ipv6=off valid=30s;
              # `set` must run before `rewrite ... break`: both are rewrite-module
              # directives and `break` stops that phase, leaving the variable unset.
              set $wger_powersync_upstream http://powersync:8080;
              rewrite ^/ps/(.*)$ /$1 break;
              proxy_pass $wger_powersync_upstream;
              proxy_http_version 1.1;
              proxy_set_header Host $http_host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $wger_forwarded_proto;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
              proxy_buffering off;
              proxy_read_timeout 1d;
              proxy_send_timeout 1d;
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

          # Grandfather-father-son retention: the newest `daily` dumps, plus the
          # newest dump of each of the last `weekly` ISO weeks and `monthly`
          # months. The timestamp is parsed from the file name, so the list
          # sorts newest-first lexicographically.
          mapfile -t dumps < <(
            ${pkgs.findutils}/bin/find ${backupDir} -mindepth 1 -maxdepth 1 -type f -name 'wger-*.sql.gz' -printf '%f\n' \
              | ${pkgs.coreutils}/bin/sort -r
          )

          declare -A keep seenWeek seenMonth
          dailyKept=0 weeksKept=0 monthsKept=0

          for name in "''${dumps[@]}"; do
            date="''${name:5:8}"

            if [ "$dailyKept" -lt ${toString cfg.backup.keep.daily} ]; then
              keep[$name]=1
              dailyKept=$((dailyKept + 1))
            fi

            if week="$(${pkgs.coreutils}/bin/date -d "$date" +%G-%V 2>/dev/null)"; then
              if [ -z "''${seenWeek[$week]:-}" ]; then
                seenWeek[$week]=1
                if [ "$weeksKept" -lt ${toString cfg.backup.keep.weekly} ]; then
                  keep[$name]=1
                  weeksKept=$((weeksKept + 1))
                fi
              fi

              month="''${date:0:6}"
              if [ -z "''${seenMonth[$month]:-}" ]; then
                seenMonth[$month]=1
                if [ "$monthsKept" -lt ${toString cfg.backup.keep.monthly} ]; then
                  keep[$name]=1
                  monthsKept=$((monthsKept + 1))
                fi
              fi
            fi
          done

          for name in "''${dumps[@]}"; do
            if [ -z "''${keep[$name]:-}" ]; then
              ${pkgs.coreutils}/bin/rm -f -- "${backupDir}/$name"
            fi
          done
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

        powersyncConfigDir = pkgs.runCommand "wger-powersync-config" { } ''
          mkdir -p "$out"

          cat > "$out/powersync.yaml" <<'YAML'
          # yaml-language-server: $schema=../schema/schema.json

          # Note that this example uses YAML custom tags for environment variable substitution.
          # Using `!env [variable name]` will substitute the value of the environment variable named
          # [variable name].
          #
          # Only environment variables with names starting with `PS_` can be substituted.
          #
          # e.g. With the environment variable `export PS_STORAGE_MONGO_URI=mongodb://localhost:27017`
          # and YAML code:
          #  uri: !env PS_STORAGE_MONGO_URI
          # The YAML will resolve to:
          #  uri: mongodb://localhost:27017
          #
          # If using VS Code see the `.vscode/settings.json` definitions which define custom tags.

          # migrations:
          #   # Migrations run automatically by default.
          #   # Setting this to true will skip automatic migrations.
          #   # Migrations can be triggered externally by altering the container `command`.
          #   disable_auto_migration: true

          # Settings for telemetry reporting
          # See https://docs.powersync.com/self-hosting/telemetry
          telemetry:
            disable_telemetry_sharing: true

            # Expose prometheus metrics on this port
            prometheus_port: 9090

          # Settings for source database replication
          replication:
            # Specify database connection details
            # Note only 1 connection is currently supported
            # Multiple connection support is on the roadmap
            connections:
              - type: postgresql
                uri: !env PS_DATABASE_URI

                # Or use individual params
                # hostname: db # From the Docker Compose service name
                # port: 5432
                # database: postgres
                # username: postgres
                # password: mypassword

                # SSL settings
                sslmode: disable # 'verify-full' (default) or 'verify-ca' or 'disable'
                # 'disable' is OK for local/private networks, not for public networks


          # Connection settings for sync bucket storage
          storage:
            type: postgresql
            uri: !env PS_STORAGE_PG_URI
            sslmode: disable

          # The port which the PowerSync API server will listen on
          port: !env PS_PORT

          # Workaround for PSYNC_S2305 bug: PowerSync counts source rows instead of DISTINCT
          # CTE results. Users with large nutrition logs (>1000 log items) can hit the limit
          # even though the number of distinct ingredients is well below it.
          # See https://github.com/powersync-ja/powersync-service/issues/682
          #     https://github.com/wger-project/flutter/issues/1237
          api:
            parameters:
              max_parameter_query_results: 2000

          # Specify sync rules
          sync_rules:
            path: sync_rules.yaml

          # Client (application end user) authentication settings
          client_auth:
            allow_local_jwks: true
            jwks_uri: !env PS_JWKS_URL

            # JWKS audience
            audience: ["powersync"]
          YAML

          cat > "$out/sync_rules.yaml" <<'YAML'
          # Note that changes to this file are not watched.
          # The service needs to be restarted for changes to take effect.

          # Warning: a user may have at most 1000 buckets, i.e. parameter-query results
          # summed across all streams. This counts the *parameter* rows, not the data
          # rows inside a bucket (a single bucket can hold any number of rows). For a
          # stream with a `with:` CTE the count is the number of rows the CTE returns,
          # so for `user_ingredients` below that is the number of distinct ingredients
          # a user has ever referenced. Exceeding the limit is a hard error
          # (PSYNC_S2305 "Too many parameter query results").
          # See https://docs.powersync.com/sync/rules/parameter-queries
          #
          # Streams are split by update frequency (cold / medium / hot) so that
          # bucket compaction can collapse the head of hot buckets without being
          # blocked by long-lived rows from cold tables.
          #
          # For details, see the documentation:
          # https://docs.powersync.com/sync/streams/overview
          # https://docs.powersync.com/maintenance-ops/compacting-buckets

          config:
            edition: 3

          streams:
            # Global reference data, shared by all users, changes rarely enough
            core:
              auto_subscribe: true
              queries:
                - SELECT * FROM core_language
                - SELECT * FROM core_license
                - SELECT * FROM core_repetitionunit
                - SELECT * FROM core_weightunit
                - SELECT * FROM exercises_exercise
                - SELECT * FROM exercises_translation
                - SELECT * FROM exercises_alias
                - SELECT * FROM exercises_exercisecomment
                - SELECT * FROM exercises_muscle
                - SELECT * FROM exercises_exercise_muscles
                - SELECT * FROM exercises_exercise_muscles_secondary
                - SELECT * FROM exercises_equipment
                - SELECT * FROM exercises_exercise_equipment
                - SELECT * FROM exercises_exercisecategory
                - SELECT * FROM exercises_exerciseimage
                - SELECT * FROM exercises_exercisevideo

            # COLD, per-user data that almost never changes after creation.
            user_profile:
              auto_subscribe: true
              queries:
                - SELECT * FROM core_userprofile WHERE CAST(user_id AS TEXT) = auth.user_id()
                - SELECT * FROM gallery_image WHERE CAST(user_id AS TEXT) = auth.user_id()

            # COLD but potentially large, only the per-user *filter set* changes when the user logs new foods
            user_ingredients:
              auto_subscribe: true
              with:
                user_ingredients: |
                  SELECT DISTINCT nutrition_synced_ingredient.id
                  FROM nutrition_synced_ingredient
                  WHERE nutrition_synced_ingredient.id IN (
                          SELECT nutrition_logitem.ingredient_id FROM nutrition_logitem
                          JOIN nutrition_nutritionplan ON nutrition_logitem.plan_id = nutrition_nutritionplan.id
                          WHERE CAST(nutrition_nutritionplan.user_id AS TEXT) = auth.user_id())
                     OR nutrition_synced_ingredient.id IN (
                          SELECT nutrition_mealitem.ingredient_id FROM nutrition_mealitem
                          JOIN nutrition_meal ON nutrition_mealitem.meal_id = nutrition_meal.id
                          JOIN nutrition_nutritionplan ON nutrition_meal.plan_id = nutrition_nutritionplan.id
                          WHERE CAST(nutrition_nutritionplan.user_id AS TEXT) = auth.user_id())
              queries:
                - SELECT * FROM nutrition_synced_ingredient AS nutrition_ingredient WHERE id IN user_ingredients
                - |
                  SELECT nutrition_image.* FROM nutrition_image
                  WHERE nutrition_image.ingredient_id IN user_ingredients
                - |
                  SELECT nutrition_ingredientweightunit.* FROM nutrition_ingredientweightunit
                  WHERE nutrition_ingredientweightunit.ingredient_id IN user_ingredients

            # MEDIUM. Edited e.g. when the user builds or edits their routine or nutrition plan,
            # but not on every workout.
            user_planning:
              auto_subscribe: true
              queries:
                # Routines (templates excluded)
                - SELECT * FROM manager_routine WHERE CAST(user_id AS TEXT) = auth.user_id() AND is_template = FALSE

                # Measurements
                - SELECT * FROM measurements_category WHERE CAST(user_id AS TEXT) = auth.user_id()
                - |
                  SELECT measurements_measurement.*
                  FROM measurements_measurement
                  INNER JOIN measurements_category
                    ON measurements_measurement.category_id = measurements_category.id
                  WHERE CAST(measurements_category.user_id AS TEXT) = auth.user_id()

                # Nutrition plan structure (not the log items)
                - SELECT * FROM nutrition_nutritionplan WHERE CAST(user_id AS TEXT) = auth.user_id()
                - |
                  SELECT nutrition_meal.*
                  FROM nutrition_meal
                  JOIN nutrition_nutritionplan
                    ON nutrition_meal.plan_id = nutrition_nutritionplan.id
                  WHERE CAST(nutrition_nutritionplan.user_id AS TEXT) = auth.user_id()
                - |
                  SELECT nutrition_mealitem.*
                  FROM nutrition_mealitem
                  JOIN nutrition_meal
                    ON nutrition_mealitem.meal_id = nutrition_meal.id
                  JOIN nutrition_nutritionplan
                    ON nutrition_meal.plan_id = nutrition_nutritionplan.id
                  WHERE CAST(nutrition_nutritionplan.user_id AS TEXT) = auth.user_id()


            # HOT. Generates  one or more new rows per workout / meal. Compaction has the
            # biggest impact here, so it must stay isolated from the other streams above
            user_activity:
              auto_subscribe: true
              queries:
                # Weight tracking
                - SELECT uuid AS id, weight, date, user_id FROM weight_weightentry WHERE CAST(user_id AS TEXT) = auth.user_id()

                # Workout sessions and per-set logs
                - SELECT * FROM manager_workoutsession WHERE CAST(user_id AS TEXT) = auth.user_id()
                - SELECT * FROM manager_workoutlog WHERE CAST(user_id AS TEXT) = auth.user_id()

                # Nutrition log entries
                - |
                  SELECT nutrition_logitem.*
                  FROM nutrition_logitem
                  JOIN nutrition_nutritionplan
                    ON nutrition_logitem.plan_id = nutrition_nutritionplan.id
                  WHERE CAST(nutrition_nutritionplan.user_id AS TEXT) = auth.user_id()
          YAML
        '';

        powersyncStorageSetupScript = pkgs.writeShellScript "wger-setup-powersync-storage" ''
          set -euo pipefail

          for attempt in $(${pkgs.coreutils}/bin/seq 1 60); do
            if ${pkgs.docker}/bin/docker exec wger-web python3 manage.py setup-powersync-storage; then
              exit 0
            fi

            if [ "$attempt" -eq 60 ]; then
              echo "Wger web container did not accept setup-powersync-storage in time" >&2
              exit 1
            fi

            ${pkgs.coreutils}/bin/sleep 2
          done
        '';

        powersyncCompactScript = pkgs.writeShellScript "wger-powersync-compact" ''
          set -euo pipefail

          ${pkgs.docker}/bin/docker run --rm \
            --name=wger-powersync-compact \
            --network=wger-net \
            --env-file=${config.sops.templates."wger-prod.env".path} \
            -v ${powersyncConfigDir}:/config:ro \
            -e POWERSYNC_CONFIG_PATH=/config/powersync.yaml \
            -e PS_JWKS_URL=http://web:8000/api/v2/powersync-keys \
            docker.io/journeyapps/powersync-service:${cfg.powersync.package} \
            compact
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
                  cmd = [
                    "postgres"
                    "-c"
                    "wal_level=logical"
                    "-c"
                    "shared_buffers=256MB"
                    "-c"
                    "effective_cache_size=768MB"
                    "-c"
                    "work_mem=8MB"
                    "-c"
                    "random_page_cost=1.1"
                    "-c"
                    "max_connections=30"
                  ];
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
                    "--shm-size=256m"
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
                    "${brandingFeaturesTemplate}:/home/wger/src/wger/software/templates/features.html:ro"
                    "${brandingTemplateFeatures}:/home/wger/src/wger/core/templates/template_features.html:ro"
                    "${brandingHeroImage}:/home/wger/src/wger/core/static/images/wger-title-foto.jpg:ro"
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
                  dependsOn = [ "wger-web" ] ++ lib.optional cfg.powersync.enable "wger-powersync";
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
              }
              // (lib.optionalAttrs cfg.powersync.enable {
                wger-powersync = {
                  image = "docker.io/journeyapps/powersync-service:${cfg.powersync.package}";
                  pull = imagePullPolicy;
                  dependsOn = [
                    "wger-db"
                    "wger-web"
                  ];
                  cmd = [
                    "start"
                    "-r"
                    "unified"
                  ];
                  volumes = [ "${powersyncConfigDir}:/config:ro" ];
                  environmentFiles = [ config.sops.templates."wger-prod.env".path ];
                  environment = {
                    POWERSYNC_CONFIG_PATH = "/config/powersync.yaml";
                    PS_JWKS_URL = "http://web:8000/api/v2/powersync-keys";
                  };
                  extraOptions = [
                    "--network=wger-net"
                    "--network-alias=powersync"
                    "--security-opt=no-new-privileges:true"
                  ];
                  autoStart = true;
                };
              });
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
                  ]
                  ++ lib.optional cfg.powersync.enable "docker-wger-powersync.service";
                  requires = [
                    "wger-docker-network.service"
                    "docker-wger-web.service"
                  ]
                  ++ lib.optional cfg.powersync.enable "docker-wger-powersync.service";
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
                  ]
                  ++ lib.optional cfg.powersync.enable "docker-wger-powersync.service";
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
              })
              // (lib.optionalAttrs cfg.powersync.enable {
                docker-wger-powersync = containerServiceDefaults // {
                  after = [
                    "wger-docker-network.service"
                    "wger-powersync-storage-setup.service"
                  ];
                  requires = [
                    "wger-docker-network.service"
                    "wger-powersync-storage-setup.service"
                  ];
                };

                wger-powersync-storage-setup = {
                  description = "Bootstrap PowerSync PostgreSQL storage role and schema";
                  after = [
                    "wger-docker-network.service"
                    "docker-wger-web.service"
                    "wger-db-password-sync.service"
                  ];
                  requires = [
                    "wger-docker-network.service"
                    "docker-wger-web.service"
                    "wger-db-password-sync.service"
                  ];
                  before = [ "docker-wger-powersync.service" ];
                  serviceConfig = {
                    Type = "oneshot";
                    ExecStart = powersyncStorageSetupScript;
                  };
                };

                wger-powersync-compact = {
                  description = "Compact Wger PowerSync bucket storage";
                  after = [ "docker-wger-powersync.service" ];
                  requires = [ "docker-wger-powersync.service" ];
                  serviceConfig = {
                    Type = "oneshot";
                    TimeoutStartSec = "1h";
                    ExecStart = powersyncCompactScript;
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

            sops.secrets.wger_jwt_private_key = {
              sopsFile = config.sops.defaultSopsFile;
              owner = "root";
              mode = "0400";
              restartUnits = containerServiceUnits;
            };

            sops.secrets.wger_jwt_public_key = {
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

            sops.secrets.wger_powersync_storage_password = lib.mkIf cfg.powersync.enable {
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
                JWT_PRIVATE_KEY=${config.sops.placeholder.wger_jwt_private_key}
                JWT_PUBLIC_KEY=${config.sops.placeholder.wger_jwt_public_key}
                REFRESH_TOKEN_LIFETIME=${toString cfg.jwt.refreshTokenLifetimeHours}
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

                SYNC_EXERCISES_CELERY=True
                SYNC_EXERCISE_IMAGES_CELERY=True
                SYNC_EXERCISE_VIDEOS_CELERY=True
                SYNC_INGREDIENTS_CELERY=False
                DOWNLOAD_INGREDIENTS_FROM=WGER

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
                ${lib.optionalString cfg.powersync.enable ''
                  PS_STORAGE_PG_URI=postgres://powersync_storage:${config.sops.placeholder.wger_powersync_storage_password}@db:5432/${dbName}
                  PS_DATABASE_URI=postgres://${dbUser}:${config.sops.placeholder.wger_db_password}@db:5432/${dbName}
                  PS_PORT=8080
                  POWERSYNC_URL_PATH=ps
                ''}
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

            # The wger nginx container only binds to 127.0.0.1, so there is
            # nothing to open in non-public mode.
            networking.firewall.allowedTCPPorts = lib.mkIf cfg.public.enable [
              80
              443
            ];

            systemd.timers.wger-db-backup = lib.mkIf cfg.backup.enable {
              description = "Timer for Wger PostgreSQL backup";
              wantedBy = [ "timers.target" ];
              timerConfig = {
                OnCalendar = cfg.backup.schedule;
                Persistent = true;
                Unit = "wger-db-backup.service";
              };
            };

            systemd.timers.wger-powersync-compact = lib.mkIf cfg.powersync.enable {
              description = "Timer for Wger PowerSync bucket compaction";
              wantedBy = [ "timers.target" ];
              timerConfig = {
                OnCalendar = cfg.powersync.compactSchedule;
                Persistent = true;
                Unit = "wger-powersync-compact.service";
              };
            };
          })
        ]
      )
    )
  ];
}
