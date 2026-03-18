#!/usr/bin/env bash
# Restart DE components on hyprland reload

# Waybar
pkill -x .waybar-wrapped >/dev/null 2>&1 || true
pkill -x waybar >/dev/null 2>&1 || true
sleep 0.4
launch-waybar &

# Notification daemon (swaync)
# pkill -x swaync || true
# while pgrep -x swaync >/dev/null; do sleep 0.1; done
# swaync &

# Wallpaper
waypaper --random

# XSettings daemon (for GTK/X11 apps)
pkill -x xsettingsd || true
sleep 0.1
xsettingsd &

# Idle management
pkill -x hypridle || true
sleep 0.2
hypridle &
