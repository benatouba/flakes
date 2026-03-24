{ config, ... }:
let
  theme = config.my.theme;
  c = theme.colors;
  accentHex = c.${theme.accent};
in
{
  config.my.hmModules = [({ pkgs, ... }: {
    home = {
      sessionVariables = {
        GTK_THEME = theme.gtk.theme;
      };
      pointerCursor = {
        package = pkgs.catppuccin-cursors;
        inherit (theme.cursor) name;
        size = 16;
        gtk.enable = true;
      };
    };
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = theme.colorScheme;
      };
    };
    gtk = {
      enable = true;
      gtk4.theme = null;
      theme = {
        name = theme.gtk.theme;
        package = pkgs.${theme.gtk.package};
      };
      cursorTheme = {
        inherit (theme.cursor) name;
      };
      iconTheme = {
        inherit (theme.icons) name;
        package = pkgs.papirus-icon-theme;
      };

      font = {
        name = theme.font.sans;
        inherit (theme.font) size;
      };
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = if theme.variant == "dark" then 1 else 0;
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
      theme=${theme.kvantum}
    '';
    xdg.configFile."Kvantum/${theme.kvantum}".source =
      "${pkgs.catppuccin-kvantum}/share/Kvantum/${theme.kvantum}";

    # GTK CSS colors generated from theme palette
    xdg.configFile."gtk-3.0/colors.css".text = ''
      /*
       * GTK Colors - ${theme.slug}
       */

      @define-color accent_color #${accentHex};
      @define-color accent_fg_color #${c.base};
      @define-color accent_bg_color #${accentHex};
      @define-color window_bg_color #${c.base};
      @define-color window_fg_color #${c.text};
      @define-color headerbar_bg_color #${c.base};
      @define-color headerbar_fg_color #${c.text};
      @define-color popover_bg_color #${c.base};
      @define-color popover_fg_color #${c.text};
      @define-color view_bg_color #${c.base};
      @define-color view_fg_color #${c.text};
      @define-color card_bg_color #${c.base};
      @define-color card_fg_color #${c.text};
      @define-color sidebar_bg_color @window_bg_color;
      @define-color sidebar_fg_color @window_fg_color;
      @define-color sidebar_border_color @window_bg_color;
      @define-color sidebar_backdrop_color @window_bg_color;
    '';
    xdg.configFile."gtk-3.0/gtk.css".text = "@import 'colors.css';";
    xdg.configFile."gtk-4.0/colors.css".text = ''
      /*
       * GTK Colors - ${theme.slug}
       */

      @define-color accent_color #${accentHex};
      @define-color accent_fg_color #${c.base};
      @define-color accent_bg_color #${accentHex};
      @define-color window_bg_color #${c.base};
      @define-color window_fg_color #${c.text};
      @define-color headerbar_bg_color #${c.base};
      @define-color headerbar_fg_color #${c.text};
      @define-color popover_bg_color #${c.base};
      @define-color popover_fg_color #${c.text};
      @define-color view_bg_color #${c.base};
      @define-color view_fg_color #${c.text};
      @define-color card_bg_color #${c.base};
      @define-color card_fg_color #${c.text};
      @define-color sidebar_bg_color @window_bg_color;
      @define-color sidebar_fg_color @window_fg_color;
      @define-color sidebar_border_color @window_bg_color;
      @define-color sidebar_backdrop_color @window_bg_color;
    '';
    xdg.configFile."gtk-4.0/gtk.css".text = "@import 'colors.css';";

    # Desktop integration (xsettingsd, electron, chromium flags)
    home.packages = with pkgs; [
      xsettingsd
    ];

    xdg.configFile."xsettingsd/xsettingsd.conf".text = ''
      Net/ThemeName "${theme.gtk.theme}"
      Net/IconThemeName "${theme.icons.name}"
      Gtk/CursorThemeName "${theme.cursor.name}"
      Net/EnableEventSounds 1
      EnableInputFeedbackSounds 0
      Xft/Antialias 1
      Xft/Hinting 1
      Xft/HintStyle "hintslight"
      Xft/RGBA "rgb"
    '';

    xdg.configFile."electron-flags.conf".text = ''
      --enable-features=UseOzonePlatform --ozone-platform=wayland --ozone-platform-hint=wayland --enable-features=WaylandWindowDecorations
    '';
    xdg.configFile."electron12-flags.conf".text = ''
      --enable-features=UseOzonePlatform --ozone-platform=wayland --ozone-platform-hint=wayland --enable-features=WaylandWindowDecorations
    '';
    xdg.configFile."chromium-flags.conf".text = ''
      --ozone-platform=wayland
      --ozone-platform-hint=wayland
      --enable-features=TouchpadOverscrollHistoryNavigation
    '';

    xdg.configFile."qt6ct/qt6ct.conf".text = ''
      [Appearance]
      color_scheme_path=/usr/share/qt6ct/colors/darker.conf
      custom_palette=true
      icon_theme=breeze-dark
      standard_dialogs=default
      style=Breeze

      [Interface]
      activate_item_on_single_click=1
      buttonbox_layout=0
      cursor_flash_time=1000
      dialog_buttons_have_icons=1
      double_click_interval=400
      gui_effects=@Invalid()
      keyboard_scheme=2
      menus_have_icons=true
      show_shortcuts_in_context_menus=true
      stylesheets=@Invalid()
      toolbutton_style=4
      underline_shortcut=1
      wheel_scroll_lines=3

      [Troubleshooting]
      force_raster_widgets=1
      ignored_applications=@Invalid()
    '';
  })];
}
