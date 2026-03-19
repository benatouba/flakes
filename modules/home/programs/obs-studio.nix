{ config, pkgs, ... }:

{
  programs.obs-studio.enable = true;
  home.file.".config/obs-studio/themes".source = ../../programs/common/obs-studio/themes;
}
