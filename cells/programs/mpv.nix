{ ... }:
{
  config.my.hmModules = [{
    programs.mpv.enable = true;
    home.file.".config/mpv/mpv.conf".source = ./mpv/mpv.conf;
    home.file.".config/mpv/scripts/file-browser.lua".source = ./mpv/scripts/file-browser.lua;
  }];
}
