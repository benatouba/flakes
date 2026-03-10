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

  xdg.configFile."hypr/hypridle.conf".source = ./hypridle.conf;
  xdg.configFile."hypr/hyprpaper.conf".source = ./hyprpaper.conf;
  xdg.configFile."hypr/assets/blank.png".source = ./assets/blank.png;
}
