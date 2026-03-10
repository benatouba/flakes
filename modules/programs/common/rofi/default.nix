{ config, pkgs, ... }:
{
  home.packages = with pkgs; [ rofi-wayland ];

  xdg.configFile."rofi" = {
    source = ../../../../dotfiles/rofi;
    recursive = true;
  };
}
