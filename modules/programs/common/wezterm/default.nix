{ config, pkgs, ... }:
{
  xdg.configFile."wezterm/wezterm.lua".source = ../../../../dotfiles/wezterm/wezterm.lua;
}
