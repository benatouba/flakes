{ config, pkgs, lib, inputs, user, ... }:

{
  home.sessionVariables = {
    GTK_THEME = lib.mkDefault "Catppuccin-Latte-Green";
  };
  home.pointerCursor = {
    package = lib.mkDefault pkgs.catppuccin-cursors;
    name = lib.mkDefault "Catppuccin-Frappe-Dark";
    size = lib.mkDefault 16;
  };
  home.pointerCursor.gtk.enable = lib.mkDefault true;
  gtk = {
    enable = lib.mkDefault true;
    theme = {
      name = lib.mkDefault "Catppuccin-Latte-Green";
      package = lib.mkDefault pkgs.catppuccin-latte-gtk;
    };
    cursorTheme = {
      name = lib.mkDefault "Catppuccin-Frappe-Dark";
    };
    iconTheme = {
      name = lib.mkDefault "Papirus-Light";
      package = lib.mkDefault pkgs.papirus-icon-theme;
    };

    font = {
      name = lib.mkDefault "JetBrainsMono Nerd Font";
      size = lib.mkDefault 12;
    };
    gtk3.extraConfig = {
      gtk-xft-antialias = lib.mkDefault 1;
      gtk-xft-hinting = lib.mkDefault 1;
      gtk-xft-hintstyle = lib.mkDefault "hintslight";
      gtk-xft-rgba = lib.mkDefault "rgb";
    };
    gtk2.extraConfig = lib.mkDefault ''
      gtk-xft-antialias=1
      gtk-xft-hinting=1
      gtk-xft-hintstyle="hintslight"
      gtk-xft-rgba="rgb"
    '';
  };
}
