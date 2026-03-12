{ config, pkgs, lib, ... }:
{
  programs = {
    btop = {
      settings = {
        color_theme = lib.mkDefault "catppuccin_latte";
      };
    };
  };
  home.file.".config/btop/themes/catppuccin_latte.theme".source = ./theme.nix;
}
