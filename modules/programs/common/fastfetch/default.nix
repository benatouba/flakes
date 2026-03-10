{ config, pkgs, ... }:
{
  xdg.configFile."fastfetch/config.jsonc".source = ../../../../dotfiles/fastfetch/config.jsonc;
}
