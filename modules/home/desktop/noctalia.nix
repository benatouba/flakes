{ pkgs, inputs, theme, ... }:

# Noctalia Shell — a Wayland desktop shell (bar, launcher, notifications, OSD, lock screen)
# built on Quickshell/Qt. Supports Hyprland natively.
#
# To activate: import this file in hosts/laptop/home.nix and add
#   inputs.noctalia.homeModules.default
# to the hmModules list in hosts/default.nix.
#
# You will also want to:
#   - Remove or disable waybar, swaync, rofi/walker, wlogout imports
#   - Add the Hyprland keybinds below to your hyprland config
#
# Hyprland keybinds to add when switching:
#   $ipc = noctalia-shell ipc call
#   bind = SUPER, SPACE, exec, $ipc launcher toggle
#   bind = SUPER, S, exec, $ipc controlCenter toggle
#   bind = SUPER, comma, exec, $ipc settings toggle
#   bindel = , XF86AudioRaiseVolume, exec, $ipc volume increase
#   bindel = , XF86AudioLowerVolume, exec, $ipc volume decrease
#   bindl = , XF86AudioMute, exec, $ipc volume muteOutput

let
  c = theme.colors;
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia-shell = {
    enable = true;

    colors = {
      primary = "#${c.${theme.accent}}";
      onPrimary = "#${c.base}";
      primaryContainer = "#${c.surface0}";
      onPrimaryContainer = "#${c.text}";

      secondary = "#${c.sapphire}";
      onSecondary = "#${c.base}";
      secondaryContainer = "#${c.surface1}";
      onSecondaryContainer = "#${c.text}";

      tertiary = "#${c.pink}";
      onTertiary = "#${c.base}";
      tertiaryContainer = "#${c.surface0}";
      onTertiaryContainer = "#${c.text}";

      error = "#${c.red}";
      onError = "#${c.base}";
      errorContainer = "#${c.surface0}";
      onErrorContainer = "#${c.red}";

      background = "#${c.base}";
      onBackground = "#${c.text}";

      surface = "#${c.base}";
      onSurface = "#${c.text}";
      surfaceVariant = "#${c.surface1}";
      onSurfaceVariant = "#${c.subtext0}";

      outline = "#${c.overlay0}";
      outlineVariant = "#${c.surface2}";
      inverseSurface = "#${c.text}";
      inverseOnSurface = "#${c.base}";
      inversePrimary = "#${c.${theme.accent}}";

      surfaceDim = "#${c.mantle}";
      surfaceBright = "#${c.surface1}";
      surfaceContainerLowest = "#${c.crust}";
      surfaceContainerLow = "#${c.mantle}";
      surfaceContainer = "#${c.base}";
      surfaceContainerHigh = "#${c.surface0}";
      surfaceContainerHighest = "#${c.surface1}";
    };

    settings = {
      bar = {
        position = "top";
        displayMode = "always";
      };

      general = {
        animations = true;
      };

      ui = {
        font = theme.font.sans;
        monospaceFont = theme.font.mono;
      };

      notifications = {
        duration = 5;
        sound = false;
      };

      dock = {
        position = "bottom";
        displayMode = "auto-hide";
      };

      audio = {
        volumeStep = 5;
        overdrive = false;
      };

      brightness = {
        step = 5;
      };

      colorSchemes = {
        darkMode = theme.variant == "dark";
      };

      location = {
        city = "Berlin";
      };
    };
  };
}
