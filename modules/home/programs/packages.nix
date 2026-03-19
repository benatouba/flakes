{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bitwarden-desktop
    claude-code
    devenv
    libreoffice-fresh
    obsidian
    ripgrep-all
    zoom-us
  ];
}
