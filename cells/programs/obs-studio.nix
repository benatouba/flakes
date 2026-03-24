{ ... }:
{
  config.my.hmModules = [{
    programs.obs-studio.enable = true;
    home.file.".config/obs-studio/themes".source = ./obs-studio/themes;
  }];
}
