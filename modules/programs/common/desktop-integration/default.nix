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
}
