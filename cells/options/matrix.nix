{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.my.matrix = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable self-hosted Matrix stack on server hosts.";
    };

    domain = mkOption {
      type = types.str;
      default = "matrix.example.com";
      description = "Public Matrix server domain for clients and federation.";
    };

    enableTelegramBridge = mkOption {
      type = types.bool;
      default = false;
      description = "Enable mautrix Telegram bridge service.";
    };

    enableWhatsappBridge = mkOption {
      type = types.bool;
      default = false;
      description = "Enable mautrix WhatsApp bridge service.";
    };

    enableSignalBridge = mkOption {
      type = types.bool;
      default = false;
      description = "Enable mautrix Signal bridge service.";
    };
  };
}
