#!/usr/bin/env bash
# Restart DE components on hyprland reload

# Bar. omarchy-restart-shell is only on PATH when my.enableOmarchyShell is set
# (cells/desktop/omarchy-shell.nix); it kills every Quickshell instance for our
# config path, waits for each to exit, and respawns through
# `hyprctl dispatch exec_cmd` so the new shell inherits the session environment
# rather than this script's, then polls IPC until it answers. That is strictly
# better than the pkill/sleep/relaunch below, which races the dying process.
if command -v omarchy-restart-shell >/dev/null 2>&1; then
  omarchy-restart-shell
else
  pkill -x .waybar-wrapped >/dev/null 2>&1 || true
  pkill -x waybar >/dev/null 2>&1 || true
  sleep 0.4
  launch-waybar &
fi

# Notification daemon (swaync)
# pkill -x swaync || true
# while pgrep -x swaync >/dev/null; do sleep 0.1; done
# swaync &

# Wallpaper
bash ~/.config/hypr/scripts/random-wallpaper.sh

# XSettings daemon (for GTK/X11 apps)
pkill -x xsettingsd || true
sleep 0.1
xsettingsd &

# Idle management
pkill -x hypridle || true
sleep 0.2
hypridle &
