#!/usr/bin/env bash
# Restart DE components on hyprland reload

# Waybar
pkill -x .waybar-wrapped 2>/dev/null
sleep 0.3
waybar &

# Notification daemon (swaync)
pkill -x swaync 2>/dev/null
sleep 0.2
swaync &

# Wallpaper
pkill -x hyprpaper 2>/dev/null
sleep 0.2
hyprpaper &

# XSettings daemon (for GTK/X11 apps)
pkill -x xsettingsd 2>/dev/null
sleep 0.1
xsettingsd &

# Idle management
pkill -x hypridle 2>/dev/null
sleep 0.2
hypridle &
