{ config, lib, pkgs, ... }:

{
  imports = [ (import ../../environment/hypr-variables.nix) ];
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    extraConfig = builtins.concatStringsSep "\n" (map builtins.readFile [
      ./mocha_theme.conf
      ./monitors.conf
      ./input.conf
      ./appearance.conf
      ./keybinds.conf
      ./workspaces.conf
      ./autostart.conf
      ./rules.conf
    ]);
  };

  xdg.portal.config = {
    hyprland = {
      default = [ "hyprland" "gtk" ];
    };
    common = {
      default = [ "gtk" ];
    };
  };

  xdg.configFile."hypr/hypridle.conf".source = ./hypridle.conf;
  xdg.configFile."hypr/hyprpaper.conf".source = ./hyprpaper.conf;
  xdg.configFile."hypr/hyprlock.conf".source = ./hyprlock.conf;
  xdg.configFile."hypr/hyprlock/status.sh" = {
    source = ./hyprlock/status.sh;
    executable = true;
  };
  xdg.configFile."hypr/scripts/refresh.sh" = {
    source = ./scripts/refresh.sh;
    executable = true;
  };
  xdg.configFile."hypr/assets/blank.png".source = ./assets/blank.png;

  # GTK colors
  xdg.configFile."gtk-3.0/colors.css".source = ../gtk/colors.css;
  xdg.configFile."gtk-3.0/gtk.css".text = "@import 'colors.css';";
  xdg.configFile."gtk-4.0/colors.css".source = ../gtk/colors.css;
  xdg.configFile."gtk-4.0/gtk.css".text = "@import 'colors.css';";

  # Waypaper
  xdg.configFile."waypaper/config.ini".source = ../waypaper/config.ini;

  # Sidepad
  xdg.configFile."sidepad/sidepad" = {
    source = ../sidepad/sidepad;
    executable = true;
  };
  xdg.configFile."sidepad/pads/wezterm".source = ../sidepad/pads/wezterm;
}
