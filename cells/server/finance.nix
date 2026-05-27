{ config, ... }:
let
  cfg = config.my.finance;
  userName = config.my.user.name;
  userEmail = config.my.user.email;
in
{
  config.my.branches.finance.nixosModules = [
    (
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        user = cfg.user;
        group = cfg.group;
        dataDir = toString cfg.dataDir;
        ledgerFile = toString cfg.ledgerFile;
        ledgerDir = builtins.dirOf ledgerFile;
        importDir = toString cfg.importDir;
        reportsDir = toString cfg.reportsDir;
        scriptsDir = toString cfg.scriptsDir;
        sourceDir = "${dataDir}/sources";
        postbankSourceDir = toString cfg.postbank.sourceDir;
        postbankOutputDir = toString cfg.postbank.outputDir;
        publicDomain = cfg.public.domain;

        postbankImportScript = pkgs.writeShellScriptBin "finance-postbank-import" ''
          set -euo pipefail

          exec ${pkgs.python3}/bin/python3 ${./finance-postbank-import.py} \
            --source-dir ${lib.escapeShellArg postbankSourceDir} \
            --output-dir ${lib.escapeShellArg postbankOutputDir} \
            --pdftotext ${lib.escapeShellArg "${pkgs.poppler-utils}/bin/pdftotext"} \
            --ledger-account ${lib.escapeShellArg cfg.postbank.ledgerAccount} \
            --income-account ${lib.escapeShellArg cfg.postbank.incomeAccount} \
            --expense-account ${lib.escapeShellArg cfg.postbank.expenseAccount} \
            --currency ${lib.escapeShellArg cfg.defaultCurrency}
        '';

        seedLedger = pkgs.writeText "finance-main.beancount" ''
          option "title" "${cfg.title}"
          option "operating_currency" "${cfg.defaultCurrency}"

          1970-01-01 open Assets:Checking
          1970-01-01 open Assets:Savings
          1970-01-01 open Assets:Receivables
          1970-01-01 open Liabilities:CreditCard
          1970-01-01 open Income:Salary
          1970-01-01 open Income:Unknown
          1970-01-01 open Expenses:Unknown
          1970-01-01 open Equity:Opening-Balances
        '';

        workspaceReadme = pkgs.writeText "finance-readme.txt" ''
          Finance workspace
          =================

          Ledger file: ${ledgerFile}
          Fava URL: http://${cfg.host}:${toString cfg.port}

          Suggested flow:
          1. Import finance PDFs into ${cfg.paperless.consumptionDir}
          2. Let Paperless OCR and archive the originals
          3. Drop executable parser scripts into ${scriptsDir}
          4. The finance-import timer runs those scripts and writes candidates into ${importDir}
          5. Review and merge candidates into ${ledgerFile}
          6. Validate with bean-check before committing ledger changes

          Postbank automation:
          - Enabled: ${lib.boolToString cfg.postbank.enable}
          - Mirrored PDF source dir: ${postbankSourceDir}
          - Generated candidate dir: ${postbankOutputDir}
          - Managed importer: finance-postbank-import
          - Sync local PDFs with: just esprimo-postbank-sync
          - Run import manually with: just esprimo-finance-import

          Paperless integration:
          - Enabled: ${lib.boolToString cfg.paperless.enable}
          - Consume dir: ${cfg.paperless.consumptionDir}
          - Media dir: ${cfg.paperless.mediaDir}
          - Web UI: ${cfg.paperless.baseUrl}

          Import timer environment:
          - FINANCE_LEDGER_FILE=${ledgerFile}
          - FINANCE_IMPORT_DIR=${importDir}
          - FINANCE_REPORTS_DIR=${reportsDir}
          - FINANCE_SCRIPTS_DIR=${scriptsDir}
          - FINANCE_SOURCE_DIR=${sourceDir}
          - FINANCE_POSTBANK_SOURCE_DIR=${postbankSourceDir}
          - FINANCE_POSTBANK_OUTPUT_DIR=${postbankOutputDir}
          - PAPERLESS_CONSUME_DIR=${cfg.paperless.consumptionDir}
          - PAPERLESS_MEDIA_DIR=${cfg.paperless.mediaDir}
          - PAPERLESS_BASE_URL=${cfg.paperless.baseUrl}
        '';

        financeImportScript = pkgs.writeShellScript "finance-import" ''
          set -euo pipefail

          export FINANCE_LEDGER_FILE=${lib.escapeShellArg ledgerFile}
          export FINANCE_IMPORT_DIR=${lib.escapeShellArg importDir}
          export FINANCE_REPORTS_DIR=${lib.escapeShellArg reportsDir}
          export FINANCE_SCRIPTS_DIR=${lib.escapeShellArg scriptsDir}
          export PAPERLESS_CONSUME_DIR=${lib.escapeShellArg cfg.paperless.consumptionDir}
          export PAPERLESS_MEDIA_DIR=${lib.escapeShellArg cfg.paperless.mediaDir}
          export PAPERLESS_BASE_URL=${lib.escapeShellArg cfg.paperless.baseUrl}
          export FINANCE_SOURCE_DIR=${lib.escapeShellArg sourceDir}
          export FINANCE_POSTBANK_SOURCE_DIR=${lib.escapeShellArg postbankSourceDir}
          export FINANCE_POSTBANK_OUTPUT_DIR=${lib.escapeShellArg postbankOutputDir}

          ${pkgs.coreutils}/bin/mkdir -p \
            "$FINANCE_IMPORT_DIR" \
            "$FINANCE_REPORTS_DIR" \
            "$FINANCE_SCRIPTS_DIR" \
            "$FINANCE_SOURCE_DIR" \
            "$FINANCE_POSTBANK_SOURCE_DIR"

          if [ "${lib.boolToString cfg.postbank.enable}" = "true" ]; then
            ${postbankImportScript}/bin/finance-postbank-import
          fi

          shopt -s nullglob
          scripts=("$FINANCE_SCRIPTS_DIR"/*)

          if [ "''${#scripts[@]}" -eq 0 ]; then
            ${pkgs.coreutils}/bin/printf 'No finance import scripts found in %s\n' "$FINANCE_SCRIPTS_DIR"
          fi

          for script in "''${scripts[@]}"; do
            if [ -f "$script" ] && [ -x "$script" ]; then
              "$script"
            fi
          done

          ${pkgs.beancount}/bin/bean-check ${lib.escapeShellArg ledgerFile} >/dev/null
        '';

        lanProxyConfig = ''
          encode zstd gzip
          @lan remote_ip private_ranges
          handle @lan {
            reverse_proxy ${cfg.host}:${toString cfg.port}
          }
          respond 403
        '';
      in
      lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = (!cfg.paperless.enable) || config.services.paperless.enable;
            message = "Finance Paperless integration requires services.paperless.enable.";
          }
          {
            assertion = (!cfg.public.enable) || cfg.public.domain != "";
            message = "Finance public access requires my.finance.public.domain to be set.";
          }
        ];

        environment.systemPackages = [
          pkgs.beancount
          pkgs.fava
        ]
        ++ lib.optionals cfg.postbank.enable [ postbankImportScript ];

        users.groups.${group} = { };

        users.users.${user} = {
          isSystemUser = true;
          inherit group;
          home = dataDir;
          createHome = true;
        };

        users.users.${userName}.extraGroups = lib.mkAfter [ group ];

        systemd.tmpfiles.rules = [
          "d ${dataDir} 2770 ${user} ${group} - -"
          "d ${ledgerDir} 2770 ${user} ${group} - -"
          "d ${importDir} 2770 ${user} ${group} - -"
          "d ${reportsDir} 2770 ${user} ${group} - -"
          "d ${sourceDir} 2770 ${user} ${group} - -"
          "d ${scriptsDir} 2770 ${user} ${group} - -"
          "d ${postbankSourceDir} 2770 ${user} ${group} - -"
          "d ${postbankOutputDir} 2770 ${user} ${group} - -"
        ];

        systemd.services.finance-bootstrap = {
          description = "Initialize finance workspace";
          wantedBy = [ "multi-user.target" ];
          before = [
            "fava.service"
            "finance-import.service"
          ];
          serviceConfig = {
            Type = "oneshot";
            User = user;
            Group = group;
            UMask = "0007";
          };
          script = ''
            set -euo pipefail

            if [ ! -e ${ledgerFile} ]; then
              ${pkgs.coreutils}/bin/install -Dm660 ${seedLedger} ${ledgerFile}
            fi

            if [ ! -e ${dataDir}/README.txt ]; then
              ${pkgs.coreutils}/bin/install -Dm660 ${workspaceReadme} ${dataDir}/README.txt
            fi
          '';
        };

        systemd.services.fava = {
          description = "Fava web UI";
          after = [
            "network.target"
            "finance-bootstrap.service"
          ];
          requires = [ "finance-bootstrap.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            User = user;
            Group = group;
            UMask = "0007";
            WorkingDirectory = ledgerDir;
            Type = "simple";
            ExecStart = lib.escapeShellArgs [
              "${pkgs.fava}/bin/fava"
              "--host"
              cfg.host
              "--port"
              (toString cfg.port)
              ledgerFile
            ];
            Restart = "on-failure";
            RestartSec = "5s";
          };
        };

        systemd.services.finance-import = {
          description = "Generate staged finance imports";
          after = [ "finance-bootstrap.service" ];
          requires = [ "finance-bootstrap.service" ];
          serviceConfig = {
            Type = "oneshot";
            User = user;
            Group = group;
            UMask = "0007";
            ExecStart = financeImportScript;
          };
        };

        systemd.timers.finance-import = {
          description = "Timer for staged finance imports";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = cfg.importSchedule;
            Persistent = true;
            Unit = "finance-import.service";
          };
        };

        services.borgbackup.jobs.paperless-office.paths = lib.mkIf config.services.paperless.enable (
          lib.mkAfter [ dataDir ]
        );

        services.caddy = {
          enable = true;
          email = lib.mkDefault userEmail;
          virtualHosts = {
            "http://${cfg.domain}".extraConfig = lanProxyConfig;
          }
          // lib.optionalAttrs cfg.public.enable {
            "${publicDomain}" = {
              extraConfig = ''
                encode zstd gzip
                header {
                  Strict-Transport-Security "max-age=31536000; includeSubDomains"
                  X-Content-Type-Options "nosniff"
                  X-Frame-Options "SAMEORIGIN"
                  Referrer-Policy "strict-origin-when-cross-origin"
                  Permissions-Policy "camera=(), microphone=(), geolocation=()"
                  -Server
                }

                reverse_proxy ${cfg.host}:${toString cfg.port} {
                  header_down -Server
                }
              '';
            };
          };
        };

        networking.firewall.allowedTCPPorts = [ 80 ] ++ lib.optionals cfg.public.enable [ 443 ];
      }
    )
  ];
}
