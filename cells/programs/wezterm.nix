{ config, ... }:
let
  inherit (config.my) theme;
in
{
  config.my.branches.desktop.hmModules = [
    {
      programs.wezterm = {
        enable = true;
        extraConfig = ''
          local wezterm = require("wezterm")
          local action = wezterm.action
          local config = wezterm.config_builder()
          local user_home = os.getenv("HOME")

          local keymap = {
            {
              key = "v",
              mods = "LEADER",
              action = action.SwitchToWorkspace({
                spawn = {
                  cwd = user_home .. "/.config/nvim/",
                  args = { "nvim", user_home .. "/.config/nvim/" },
                },
              }),
            },
            {
              key = "h",
              mods = "LEADER",
              action = action.SwitchToWorkspace({
                spawn = {
                  cwd = user_home .. "/.config/hypr/",
                  args = { "nvim", user_home .. "/.config/hypr/hyprland.conf" },
                },
              }),
            },
            {
              key = "w",
              mods = "LEADER",
              action = action.SwitchToWorkspace({
                spawn = {
                  cwd = user_home .. "/.config/wezterm/",
                  args = { "nvim", user_home .. "/.config/wezterm/wezterm.lua" },
                },
              }),
            },
          }

          config.keys = keymap
          config.set_environment_variables = {
            COLORTERM = "truecolor",
          }
          config.term = "wezterm"
          config.window_decorations = "NONE"
          config.use_resize_increments = true
          config.adjust_window_size_when_changing_font_size = false
          config.default_gui_startup_args = { "connect", "unix" }

          config.color_scheme = "${theme.weztermColorScheme}"

          config.audible_bell = "Disabled"
          config.font = wezterm.font_with_fallback({
            { family = "${theme.font.mono}", weight = "Regular", harfbuzz_features = { "calt=1", "clig=1", "liga=1" } },
            "Fira Code",
            "Noto Color Emoji",
            "Noto Emoji",
            "Noto Sans Symbols",
            "DejaVu Sans Mono",
            "Apple Color Emoji",
            "JoyPixels",
          })
          config.check_for_updates = false
          config.inactive_pane_hsb = {
            hue = 1.0,
            saturation = 1.0,
            brightness = 1.0,
          }
          config.window_background_opacity = 0.95
          config.text_background_opacity = 1
          config.enable_tab_bar = false
          config.enable_scroll_bar = true
          config.scrollback_lines = 3500

          return config
        '';
      };
    }
  ];
}
