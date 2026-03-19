{ config, pkgs, ... }:
{
  home.packages = with pkgs; [ wlogout ];

  xdg.configFile."wlogout" = {
    source = ../../../dotfiles/wlogout;
    recursive = true;
  };
}
