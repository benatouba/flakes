{ config, lib, pkgs, user, ... }:

{
  imports =
    [ (import ../../../modules/desktop/hyprland/home.nix) ] ++
    [ (import ../../../modules/editors/neovim.nix) ] ++
    [ (import ../../../modules/scripts) ] ++
    (import ../../../modules/shell) ++
    (import ../../../modules/programs/wayland) ++
    (import ../../../modules/theme/catppuccin-dark/wayland);
    # (import ../../../modules/theme/catppuccin-light/wayland) ++
    # (import ../../../modules/theme/nord/wayland);

  home = {
    username = "${user}";
    homeDirectory = "/home/${user}";
  };
  programs = {
    home-manager.enable = true;
  };

  home.stateVersion = "25.05";
}
