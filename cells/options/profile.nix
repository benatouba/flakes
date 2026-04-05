{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.my = {
    profile = {
      branches = mkOption {
        type = types.listOf types.str;
        default = [
          "base"
          "desktop"
          "security"
          "legacy"
          "addons"
        ];
        description = "Global branch set shared by all hosts.";
      };

      theme = mkOption {
        type = types.str;
        default = "catppuccin-mocha";
      };

      security.level = mkOption {
        type = types.enum [
          "balanced"
          "hardened"
        ];
        default = "balanced";
      };

      addons = {
        ergonomics.enable = mkOption {
          type = types.bool;
          default = true;
        };

        observability.enable = mkOption {
          type = types.bool;
          default = true;
        };

        deployment.enable = mkOption {
          type = types.bool;
          default = true;
        };

        attic.enable = mkOption {
          type = types.bool;
          default = false;
        };
      };
    };

    branches = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            description = mkOption {
              type = types.str;
              default = "";
            };
            nixosModules = mkOption {
              type = types.listOf types.deferredModule;
              default = [ ];
            };
            hmModules = mkOption {
              type = types.listOf types.deferredModule;
              default = [ ];
            };
          };
        }
      );
      default = { };
    };
  };
}
