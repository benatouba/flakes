{ config, lib, pkgs, theme, ... }:

let
  # Generate Hyprland theme conf from theme colors
  themeConf = lib.concatStringsSep "\n"
    (lib.mapAttrsToList (name: hex:
      "$" + name + " = rgb(" + hex + ")\n" +
      "$" + name + "Alpha = " + hex
    ) theme.colors);
in
{
  imports = [ ../../environment.nix ];
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null; # portal is managed at the NixOS level
    extraConfig = builtins.concatStringsSep "\n" ([
      themeConf
    ] ++ (map builtins.readFile [
      ./conf/monitors.conf
      ./conf/input.conf
      ./conf/appearance.conf
      ./conf/keybinds.conf
      ./conf/workspaces.conf
      ./conf/autostart.conf
      ./conf/rules.conf
    ]));
  };

  xdg.configFile."hypr/hypridle.conf".source = ./conf/hypridle.conf;
  xdg.configFile."hypr/hyprpaper.conf".source = ./conf/hyprpaper.conf;
  xdg.configFile."hypr/hyprlock.conf".source = ./conf/hyprlock.conf;
  xdg.configFile."hypr/hyprlock/status.sh" = {
    source = ./conf/hyprlock/status.sh;
    executable = true;
  };
  xdg.configFile."hypr/scripts/refresh.sh" = {
    source = ./conf/scripts/refresh.sh;
    executable = true;
  };
  xdg.configFile."hypr/scripts/random-wallpaper.sh" = {
    source = ./conf/scripts/random-wallpaper.sh;
    executable = true;
  };
  xdg.configFile."hypr/scripts/toggle-charge.sh" = {
    source = ./conf/scripts/toggle-charge.sh;
    executable = true;
  };
  xdg.configFile."hypr/scripts/power.sh" = {
    source = ./conf/scripts/power.sh;
    executable = true;
  };
  xdg.configFile."hypr/assets/blank.png".source = ./conf/assets/blank.png;

  # Waypaper
  xdg.configFile."waypaper/config.ini".source = ../../../desktop/waypaper/config.ini;

  # Sidepad
  xdg.configFile."sidepad/sidepad" = {
    source = ../../../desktop/sidepad/sidepad;
    executable = true;
  };
  xdg.configFile."sidepad/pads/wezterm".source = ../../../desktop/sidepad/pads/wezterm;
}
