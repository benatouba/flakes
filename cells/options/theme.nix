{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.my.theme = mkOption {
    type = types.submodule {
      options = {
        slug = mkOption { type = types.str; };
        variant = mkOption {
          type = types.enum [
            "dark"
            "light"
          ];
        };
        colors = mkOption {
          type = types.submodule {
            options = builtins.listToAttrs (
              map
                (name: {
                  inherit name;
                  value = mkOption { type = types.str; };
                })
                [
                  "rosewater"
                  "flamingo"
                  "pink"
                  "mauve"
                  "red"
                  "maroon"
                  "peach"
                  "yellow"
                  "green"
                  "teal"
                  "sky"
                  "sapphire"
                  "blue"
                  "lavender"
                  "text"
                  "subtext1"
                  "subtext0"
                  "overlay2"
                  "overlay1"
                  "overlay0"
                  "surface2"
                  "surface1"
                  "surface0"
                  "base"
                  "mantle"
                  "crust"
                ]
            );
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
            options = builtins.listToAttrs (
              map (n: {
                name = "gradient_color_${toString n}";
                value = mkOption { type = types.str; };
              }) (lib.range 1 8)
            );
          };
        };
      };
    };
  };
}
