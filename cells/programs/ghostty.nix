# Ghostty is the default desktop terminal; WezTerm stays installed as a fallback.
# Colors come from catppuccin.ghostty in cells/theme.
{ config, ... }:
let
  inherit (config.my) theme;
in
{
  config.my.branches.desktop.hmModules = [
    {
      programs.ghostty = {
        enable = true;
        systemd.enable = true;
        enableZshIntegration = true;
        settings = {
          font-family = [
            theme.font.mono
            "Fira Code"
            "Noto Color Emoji"
            "Noto Emoji"
            "Noto Sans Symbols"
            "DejaVu Sans Mono"
          ];
          font-feature = [
            "calt"
            "clig"
            "liga"
          ];
          background-opacity = 0.95;
          window-decoration = "none";
          window-show-tab-bar = "never";
          bell-features = "no-audio,no-system";
          scrollbar = "system";
          # Same history as WezTerm's scrollback_lines; the default byte cap still applies.
          scrollback-limit-lines = 3500;
          keybind = [
            "ctrl+shift+w=close_surface"
            "ctrl+alt+n=new_tab"
            "ctrl+tab=next_tab"
            "ctrl+shift+tab=previous_tab"
          ];
          confirm-close-surface = "always";
          cursor-style = "block";
          cursor-style-blink = false;
          term = "xterm-ghostty";
          # Keep the default block cursor at the prompt and use xterm-256color over SSH.
          shell-integration-features = "no-cursor,ssh-env,no-ssh-terminfo";
        };
      };
    }
  ];
}
