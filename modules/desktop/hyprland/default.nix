{ config, lib, pkgs, inputs, ... }:

{
  imports = [ ../../programs/wayland/waybar/hyprland_waybar.nix ];

  programs.hyprland.enable = true;

  environment.systemPackages = with pkgs; [
    inputs.hypr-contrib.packages.${pkgs.system}.grimblast
    inputs.hyprpicker.packages.${pkgs.system}.hyprpicker
    swaylock-effects
    pamixer
  ];

  security.pam.services.swaylock = { };

  xdg.portal = {
    enable = true;
    config = {
      common = {
        default = [
          "*"
        ];
      };
    };
  };
}
