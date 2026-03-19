{ pkgs, user, theme, ... }:

{
  imports = [
    ../../modules/home/desktop/hyprland
    ../../modules/home/desktop/notifications.nix
    ../../modules/home/desktop/wlogout.nix
    ../../modules/home/desktop/walker.nix
    ../../modules/home/theme.nix
    ../../modules/home/environment.nix
    ../../modules/home/shell/zsh.nix
    ../../modules/home/shell/starship.nix
    ../../modules/home/shell/bash.nix
    ../../modules/home/shell/git.nix
    ../../modules/home/programs/wezterm.nix
    ../../modules/home/programs/btop.nix
    ../../modules/home/programs/cava.nix
    ../../modules/home/programs/rofi.nix
    ../../modules/home/programs/bat.nix
    ../../modules/home/programs/neovim.nix
    ../../modules/home/programs/tmux.nix
    ../../modules/home/programs/packages.nix
    ../../modules/home/programs/fastfetch.nix
    ../../modules/home/programs/gpg.nix
    ../../modules/home/programs/lazygit.nix
    ../../modules/home/programs/matugen.nix
    ../../modules/home/programs/music.nix
    ../../modules/home/programs/obs-studio.nix
    ../../modules/home/programs/search.nix
    ../../modules/home/programs/yazi.nix
    ../../modules/home/programs/yt-dlp.nix
    ../../modules/home/programs/zathura.nix
    ../../modules/home/programs/mpv.nix
    ../../modules/home/programs/imgview.nix
    ../../modules/home/scripts/wallpaper.nix
    ../../modules/home/scripts/screenshot.nix
    ../../modules/home/scripts/waybar.nix
    ../../modules/home/impermanence.nix
  ];

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
