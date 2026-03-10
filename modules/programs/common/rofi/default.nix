{ config, pkgs, ... }:
{
  home.packages = with pkgs; [ rofi ];

  xdg.configFile."rofi" = {
    source = ../../../../dotfiles/rofi;
    recursive = true;
  };
}
