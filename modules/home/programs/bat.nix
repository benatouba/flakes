{ config, pkgs, ... }:
{
  xdg.configFile."bat" = {
    source = ../../../dotfiles/bat;
    recursive = true;
  };
}
