{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.my.finance = {
    enable = mkEnableOption "ledger-first personal finance stack with Beancount and Fava";

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/finance";
      description = "State root for ledgers, import staging, scripts, and generated reports.";
    };

    user = mkOption {
      type = types.str;
      default = "finance";
      description = "System user that owns the finance working tree.";
    };

    group = mkOption {
      type = types.str;
      default = "finance";
      description = "System group that owns the finance working tree.";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Listen host for the Fava web UI.";
    };

    port = mkOption {
      type = types.port;
      default = 5000;
      description = "Listen port for the Fava web UI.";
    };

    domain = mkOption {
      type = types.str;
      default = "fava.example.com";
      description = "Public domain used when exposing Fava through Caddy.";
    };

    title = mkOption {
      type = types.str;
      default = "Finance";
      description = "Title shown in the Fava UI.";
    };

    ledgerFile = mkOption {
      type = types.str;
      default = "/var/lib/finance/ledger/main.beancount";
      description = "Primary Beancount ledger file opened by Fava and validation jobs.";
    };

    importDir = mkOption {
      type = types.str;
      default = "/var/lib/finance/imports";
      description = "Directory for staged import output and candidate entries.";
    };

    reportsDir = mkOption {
      type = types.str;
      default = "/var/lib/finance/reports";
      description = "Directory for generated finance reports and exports.";
    };

    scriptsDir = mkOption {
      type = types.str;
      default = "/var/lib/finance/scripts";
      description = "Directory for parser and automation scripts.";
    };

    defaultCurrency = mkOption {
      type = types.str;
      default = "EUR";
      description = "Default commodity used in the initial Beancount skeleton.";
    };

    importSchedule = mkOption {
      type = types.str;
      default = "hourly";
      description = "systemd calendar expression for the finance import timer.";
    };

    paperless = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Expose Paperless paths in the generated finance workspace notes.";
      };

      consumptionDir = mkOption {
        type = types.str;
        default = "/var/lib/paperless/consume/import/finance";
        description = "Paperless consume subdirectory reserved for finance documents.";
      };

      mediaDir = mkOption {
        type = types.str;
        default = "/var/lib/paperless/media/documents/originals";
        description = "Paperless originals directory used by custom import tooling when needed.";
      };

      baseUrl = mkOption {
        type = types.str;
        default = "http://paperless.esprimo";
        description = "Base URL to reference the Paperless web UI from finance notes and tooling.";
      };
    };

    postbank = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Generate staged Beancount candidates from mirrored Postbank statement PDFs.";
      };

      sourceDir = mkOption {
        type = types.str;
        default = "/var/lib/finance/sources/postbank";
        description = "Host directory that stores the mirrored Postbank PDF corpus.";
      };

      outputDir = mkOption {
        type = types.str;
        default = "/var/lib/finance/imports/postbank";
        description = "Directory where generated Postbank candidate entries are written.";
      };

      ledgerAccount = mkOption {
        type = types.str;
        default = "Assets:Checking";
        description = "Beancount account that receives parsed Postbank statement balances and transactions.";
      };

      incomeAccount = mkOption {
        type = types.str;
        default = "Income:Unknown";
        description = "Placeholder account used for positive Postbank transactions.";
      };

      expenseAccount = mkOption {
        type = types.str;
        default = "Expenses:Unknown";
        description = "Placeholder account used for negative Postbank transactions.";
      };
    };

    public = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Expose Fava through the host Caddy reverse proxy with ACME TLS.";
      };

      domain = mkOption {
        type = types.str;
        default = "";
        description = "Public HTTPS domain for Fava.";
      };
    };
  };
}
