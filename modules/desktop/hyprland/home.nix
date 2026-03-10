{ config, lib, pkgs, ... }:

{
  imports = [ (import ../../environment/hypr-variables.nix) ];
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    extraConfig = builtins.readFile ./mocha_theme.conf + "\n" + builtins.readFile ./hyprland.conf + "\n" + builtins.readFile ./rules.conf;
  };
}
