-- Pull in the wezterm API
local wezterm = require("wezterm") ---@type Wezterm
local action = wezterm.action

local config = wezterm.config_builder() ---@class Config
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

-- config.font_size = 17.0
config.keys = keymap
-- config.leader = { key = "b", mods = "CTRL", timeout_milliseconds = 1000 }
config.set_environment_variables = {
  COLORTERM = "truecolor",
}
config.term = "wezterm"
config.window_decorations = "NONE"
config.use_resize_increments = true
config.adjust_window_size_when_changing_font_size = false
-- config.unix_domains = { { name = "unix" } }
config.default_gui_startup_args = { "connect", "unix" }

local function get_appearance()
  if wezterm.gui then
    return wezterm.gui.get_appearance()
  end
  return 'Dark'
end

local function scheme_for_appearance(appearance)
  if appearance:find("Dark") then
    return "catppuccin-mocha"
  else
    return "Catppuccin Latte"
  end
end

-- Set the color scheme using an event handler instead
wezterm.on('window-config-reloaded', function(window, pane)
  local overrides = window:get_config_overrides() or {}
  local appearance = get_appearance()
  local scheme = scheme_for_appearance(appearance)
  if overrides.color_scheme ~= scheme then
    overrides.color_scheme = scheme
    window:set_config_overrides(overrides)
  end
end)

-- Set initial color scheme
-- config.color_scheme = scheme_for_appearance(get_appearance())
config.color_scheme = "catppuccin-mocha"

-- This is where you actually apply your config choices
config.audible_bell = "Disabled"
config.font = wezterm.font_with_fallback({
  { family = "JetBrains Mono", weight = "Regular", harfbuzz_features = { "calt=1", "clig=1", "liga=1" } },
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
config.window_background_opacity = 0.9
config.text_background_opacity = 0.9
config.enable_tab_bar = false
config.enable_scroll_bar = true
config.scrollback_lines = 3500

-- and finally, return the configuration to wezterm
return config
