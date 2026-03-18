{ config, pkgs, lib, inputs, user, ... }:

{
  home.sessionVariables = {
    GTK_THEME = "Catppuccin-Latte-Green";
  };
  home.pointerCursor = {
    package = pkgs.catppuccin-cursors;
    name = "Catppuccin-Latte-Dark";
    size = 16;
  };
  home.pointerCursor.gtk.enable = true;
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-light";
    };
  };
  gtk = {
    enable = true;
    theme = {
      name = "Catppuccin-Latte-Green";
      package = pkgs.catppuccin-latte-gtk;
    };
    cursorTheme = {
      name = "Catppuccin-Latte-Dark";
    };
    iconTheme = {
      name = "Papirus-Light";
      package = pkgs.papirus-icon-theme;
    };

    font = {
      name = "Noto Sans";
      size = 11;
    };
    gtk3.extraConfig = {
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
    };
    gtk2.extraConfig = ''
      gtk-xft-antialias=1
      gtk-xft-hinting=1
      gtk-xft-hintstyle="hintslight"
      gtk-xft-rgba="rgb"
    '';
  };

  # Qt theming via Kvantum
  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };
  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=catppuccin-latte-mauve
  '';
  xdg.configFile."Kvantum/catppuccin-latte-mauve".source =
    "${pkgs.catppuccin-kvantum}/share/Kvantum/catppuccin-latte-mauve";
}
