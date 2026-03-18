# modules/programs/user-packages.nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bitwarden-desktop  # temporarily disabled — electron 39 build broken in nixpkgs
    claude-code
    libreoffice-fresh
    obsidian
    ripgrep-all
    zoom-us
  ];
}

