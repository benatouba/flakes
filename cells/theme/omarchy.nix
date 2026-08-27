# Bridge between this repo's Catppuccin palette (cells/theme/palette.nix) and
# the two TOML files the Omarchy shell reads from
# ~/.local/state/omarchy/current/theme (see shell/Commons/Color.qml).
#
# Exposed as config.my.omarchyTheme so cells/desktop/omarchy-shell.nix can drop
# the rendered files into place. Nothing here is a new source of truth: change
# my.profile.theme and the shell follows along with GTK, Qt, wezterm and waybar.
{ config, lib, ... }:
let
  theme = config.my.theme;
  c = theme.colors;

  # Omarchy's colors.toml has a fixed vocabulary. Catppuccin names do not line
  # up with it one-for-one, so map by role rather than by name.
  colors = {
    mode = theme.variant;

    accent = c.${theme.accent};
    selection = c.surface1;
    muted = c.overlay0;

    background = c.base;
    dark_background = c.mantle;
    darker_background = c.crust;
    lighter_background = c.surface0;

    foreground = c.text;
    dark_foreground = c.overlay1;
    light_foreground = c.subtext1;
    bright_foreground = c.rosewater;

    inherit (c)
      red
      yellow
      green
      blue
      ;
    orange = c.peach;
    cyan = c.teal;
    magenta = c.pink;
    brown = c.maroon;

    bright_red = c.maroon;
    bright_yellow = c.peach;
    bright_green = c.teal;
    bright_cyan = c.sky;
    bright_blue = c.sapphire;
    bright_magenta = c.mauve;
  };

  # Matches decoration.col.active_border in cells/desktop/hyprland.nix, so the
  # shell's popup/notification borders stay aligned with the window borders.
  # Color.qml understands the Hyprland gradient form and takes the first stop
  # wherever it needs a flat colour.
  activeBorder = "rgb(${c.flamingo}) rgb(${c.rosewater}) 45deg";
  activeBorderForeground = "rgb(${c.rosewater}) rgb(${c.text}) 45deg";

  # Color.qml only accepts "#rrggbb" or "rgb(rrggbb)"; a bare hex string is
  # rejected and silently falls back to the foundational palette.
  hash = hex: "#${hex}";

  fg = hash colors.foreground;
  bg = hash colors.background;

  # Reproduces the values upstream generates from default/themed/shell.toml.tpl.
  # Written out as Nix rather than rendered from the template so an input bump
  # cannot silently change the look, and so the alphas that carry Omarchy's
  # visual language are reviewable here. Anything omitted falls back to the
  # foundational palette in Color.qml, which is why sections for plugins we do
  # not ship (lock, polkit, menu, launcher, image-picker) are absent.
  shell = {
    bar = {
      background = bg;
      # Below 1.0 so the blur-omarchy layerrule in hyprland/rules.conf reads as
      # frosted glass rather than a flat fill. Hyprland's ignore_alpha cutoff
      # there is 0.6, so these have to stay above it to be blurred at all.
      background-alpha = 0.85;
      text = fg;
      active = hash colors.red;
      scale-with-font = true;
      size-horizontal = 26;
      size-vertical = 28;
    };

    hyprland = {
      active-border = activeBorder;
      active-border-foreground = activeBorderForeground;
    };

    controls = {
      normal-color = fg;
      normal-fill-alpha = 0.04;
      normal-border = fg;
      normal-border-width = 1;
      normal-border-alpha = 0.4;

      hover-cursor-color = fg;
      hover-cursor-fill-alpha = 0.08;
      hover-cursor-border = fg;
      hover-cursor-border-width = 1;
      hover-cursor-border-alpha = 0.25;

      focus-color = fg;
      focus-fill-alpha = 0.08;
      focus-border = fg;
      focus-border-width = 1;
      focus-border-alpha = 0.25;

      selected-color = fg;
      selected-fill-alpha = 0.18;
      selected-border = fg;
      selected-border-width = 0;
      selected-border-alpha = 1.0;

      pressed-fill-alpha = 0.22;
      selection-fill-alpha = 0.35;
    };

    spacing = {
      scale = 1.0;
      scale-with-font = true;
    };

    font = {
      base-size = theme.font.size + 1;
    };

    popups = {
      background = bg;
      background-alpha = 0.9;
      text = fg;
      border = "hyprland.active-border";
      border-alpha = 1.0;
    };

    tooltip = {
      background = bg;
      background-alpha = 0.97;
      text = fg;
      border = "hyprland.active-border-foreground";
      border-alpha = 1.0;
    };

    notifications = {
      background = bg;
      background-alpha = 0.9;
      text = fg;
      border = "hyprland.active-border";
      border-alpha = 1.0;
      countdown = hash colors.accent;
    };
  };
in
{
  options.my.omarchyTheme = lib.mkOption {
    type = lib.types.attrs;
    internal = true;
    readOnly = true;
    description = "Omarchy shell theme data derived from my.theme.";
  };

  config.my.omarchyTheme = {
    inherit colors shell;
    # colors.toml wants bare hex with a leading #; the palette stores it without.
    colorsToml = lib.mapAttrs (name: value: if name == "mode" then value else "#${value}") colors;
  };
}
