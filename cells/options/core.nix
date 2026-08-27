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

    enableNoctalia = mkOption {
      type = types.bool;
      default = false;
    };

    enableOmarchyShell = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Replace Waybar and swaync with the vendored Omarchy 4 Quickshell bar,
        OSD and notification daemon. rofi, hyprlock, hypridle, wlogout and
        hyprpaper are unaffected. Flipping this back off restores Waybar on the
        next rebuild.
      '';
    };
  };
}
