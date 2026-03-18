{ config, pkgs, theme ? "dark", ... }:

let
  gtkThemeName = if theme == "light" then "Catppuccin-Latte-Green" else "Catppuccin-Frappe-Pink";
  iconThemeName = if theme == "light" then "Papirus-Light" else "Papirus-Dark";
  cursorThemeName = if theme == "light" then "Catppuccin-Latte-Dark" else "Catppuccin-Frappe-Dark";
in
{
  home.packages = with pkgs; [
    xsettingsd
  ];

  xdg.configFile."xsettingsd/xsettingsd.conf".text = ''
    Net/ThemeName "${gtkThemeName}"
    Net/IconThemeName "${iconThemeName}"
    Gtk/CursorThemeName "${cursorThemeName}"
    Net/EnableEventSounds 1
    EnableInputFeedbackSounds 0
    Xft/Antialias 1
    Xft/Hinting 1
    Xft/HintStyle "hintslight"
    Xft/RGBA "rgb"
  '';
  xdg.configFile."electron-flags.conf".source = ../../../../dotfiles/electron-flags.conf;
  xdg.configFile."electron12-flags.conf".source = ../../../../dotfiles/electron-flags.conf;
  xdg.configFile."chromium-flags.conf".source = ../../../../dotfiles/chromium-flags.conf;
}
