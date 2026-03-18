{ config, lib, pkgs, theme ? "dark", ... }:

let
  themeConf = if theme == "light" then ./latte_theme.conf else ./mocha_theme.conf;
  gtkColors = if theme == "light" then ../gtk/colors-latte.css else ../gtk/colors.css;
in
{
  imports = [ (import ../../environment/hypr-variables.nix) ];
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    extraConfig = builtins.concatStringsSep "\n" (map builtins.readFile [
      themeConf
      ./monitors.conf
      ./input.conf
      ./appearance.conf
      ./keybinds.conf
      ./workspaces.conf
      ./autostart.conf
      ./rules.conf
    ]);
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
  xdg.configFile."hypr/scripts/random-wallpaper.sh" = {
    source = ./scripts/random-wallpaper.sh;
    executable = true;
  };
  xdg.configFile."hypr/scripts/toggle-charge.sh" = {
    source = ./scripts/toggle-charge.sh;
    executable = true;
  };
  xdg.configFile."hypr/scripts/power.sh" = {
    source = ./scripts/power.sh;
    executable = true;
  };
  xdg.configFile."hypr/assets/blank.png".source = ./assets/blank.png;

  # GTK colors - selected based on theme
  xdg.configFile."gtk-3.0/colors.css".source = gtkColors;
  xdg.configFile."gtk-3.0/gtk.css".text = "@import 'colors.css';";
  xdg.configFile."gtk-4.0/colors.css".source = gtkColors;
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
