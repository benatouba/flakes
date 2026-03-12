# modules/programs/obsidian.nix
{ lib, pkgs, ... }:
with lib;
{
  options.programs.obsidian = {
    enable = mkEnableOption "Obsidian";
  };
  config = mkIf config.programs.obsidian.enable {
    home.packages = [ pkgs.obsidian ];
    # Add xdg.desktopEntries for launcher icons, home.file for vaults if needed
    xdg.desktopEntries.obsidian = {
      name = "Obsidian";
      exec = "${pkgs.obsidian}/bin/obsidian %U";
      mimeTypes = [ "application/x-obsidian" ];
    };
  };
}
