{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bitwarden-desktop
    claude-code
    commitmsgfmt
    devenv
    libreoffice-fresh
    obsidian
    ripgrep-all
    zoom-us
  ];
}
