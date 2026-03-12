# modules/programs/user-packages.nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bitwarden-desktop
    claude-code
    obsidian
    ripgrep-all
    zoom-us
  ];
}

