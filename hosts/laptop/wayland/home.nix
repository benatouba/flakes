{ pkgs, user, theme, ... }:

let
  themeModule = if theme == "light"
    then ../../../modules/theme/catppuccin-light/wayland
    else ../../../modules/theme/catppuccin-dark/wayland;
in
{
  imports = [
    (import ../../../modules/desktop/hyprland/home.nix)
  ]
  ++ [ (import ../../../modules/editors/neovim.nix) ]
  ++ [ (import ../../../modules/scripts) ]
  ++ (import ../../../modules/shell)
  ++ (import ../../../modules/programs/wayland)
  ++ (import themeModule);

  home = {
    username = "${user}";
    homeDirectory = "/home/${user}";
  };
  programs = {
    home-manager.enable = true;
    chromium = {
      enable = true;
      package = pkgs.brave;
      extensions = [
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
        { id = "hfjbmagddngcpeloejdejnfgbamkjaeg"; } # Vimium C
      ];
    };
  };

  home.stateVersion = "25.05";
}
