{ config, pkgs, theme ? "dark", ... }:

let
  weztermColorScheme = if theme == "light" then "Catppuccin Latte" else "Catppuccin Mocha";
  weztermConfig = builtins.replaceStrings
    [ "@weztermColorScheme@" ]
    [ weztermColorScheme ]
    (builtins.readFile ../../../../dotfiles/wezterm/wezterm.lua);
in
{
  home.packages = with pkgs; [ wezterm ];
  xdg.configFile."wezterm/wezterm.lua".text = weztermConfig;
}
