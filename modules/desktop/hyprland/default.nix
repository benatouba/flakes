{ config, lib, pkgs, inputs, ... }:

{
  imports = [ ../../programs/wayland/waybar/hyprland_waybar.nix ];

  programs.hyprland.enable = true;

  environment.systemPackages = with pkgs; [
    inputs.hyprpicker.packages.${pkgs.stdenv.hostPlatform.system}.hyprpicker
    hyprlock
    pamixer
  ];

  security.pam.services.hyprlock = { };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config = {
      hyprland = {
        default = [ "hyprland" "gtk" ];
      };
      common = {
        default = [ "*" ];
      };
    };
  };
}
