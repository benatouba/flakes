{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.my = {
    user = {
      name = mkOption {
        type = types.str;
        default = "ben";
        description = "Unix username";
      };
      fullName = mkOption {
        type = types.str;
        default = "Benjamin Schmidt";
      };
      email = mkOption {
        type = types.str;
        default = "benschmidt@live.de";
      };
      githubUser = mkOption {
        type = types.str;
        default = "benatouba";
      };
    };

    stateVersion = mkOption {
      type = types.str;
      default = "25.05";
    };

    theme = mkOption {
      type = types.submodule {
        options = {
          slug = mkOption { type = types.str; };
          variant = mkOption { type = types.enum [ "dark" "light" ]; };
          colors = mkOption {
            type = types.submodule {
              options = builtins.listToAttrs (map (name: {
                inherit name;
                value = mkOption { type = types.str; };
              }) [
                "rosewater" "flamingo" "pink" "mauve" "red" "maroon"
                "peach" "yellow" "green" "teal" "sky" "sapphire"
                "blue" "lavender" "text" "subtext1" "subtext0"
                "overlay2" "overlay1" "overlay0"
                "surface2" "surface1" "surface0"
                "base" "mantle" "crust"
              ]);
            };
          };
          accent = mkOption { type = types.str; };
          borderColor = mkOption { type = types.str; };
          gtk = mkOption {
            type = types.submodule {
              options = {
                theme = mkOption { type = types.str; };
                package = mkOption { type = types.str; };
              };
            };
          };
          icons = mkOption {
            type = types.submodule {
              options.name = mkOption { type = types.str; };
            };
          };
          cursor = mkOption {
            type = types.submodule {
              options.name = mkOption { type = types.str; };
            };
          };
          colorScheme = mkOption { type = types.str; };
          kvantum = mkOption { type = types.str; };
          weztermColorScheme = mkOption { type = types.str; };
          starshipPalette = mkOption { type = types.str; };
          waybarVariation = mkOption { type = types.str; };
          font = mkOption {
            type = types.submodule {
              options = {
                sans = mkOption { type = types.str; };
                mono = mkOption { type = types.str; };
                size = mkOption { type = types.int; };
                monoSize = mkOption { type = types.int; };
              };
            };
          };
          cava = mkOption {
            type = types.submodule {
              options = builtins.listToAttrs (map (n: {
                name = "gradient_color_${toString n}";
                value = mkOption { type = types.str; };
              }) (lib.range 1 8));
            };
          };
        };
      };
    };

    enableNoctalia = mkOption {
      type = types.bool;
      default = false;
    };
    nixosModules = mkOption {
      type = types.listOf types.deferredModule;
      default = [];
    };
    hmModules = mkOption {
      type = types.listOf types.deferredModule;
      default = [];
    };
    hosts = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          system = mkOption {
            type = types.str;
            default = "x86_64-linux";
          };
          nixosModules = mkOption {
            type = types.listOf types.deferredModule;
            default = [];
          };
          hmModules = mkOption {
            type = types.listOf types.deferredModule;
            default = [];
          };
          hardwareModules = mkOption {
            type = types.listOf types.deferredModule;
            default = [];
          };
        };
      });
      default = {};
    };
  };
}
