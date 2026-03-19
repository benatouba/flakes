{ lib, pkgs, user, ... }:

{
  programs.mpv.enable = true;
  home.file.".config/mpv/mpv.conf".source = ../../programs/wayland/mpv/mpv.conf;
  home.file.".config/mpv/scripts/file-browser.lua".source = ../../programs/wayland/mpv/scripts/file-browser.lua;
}
