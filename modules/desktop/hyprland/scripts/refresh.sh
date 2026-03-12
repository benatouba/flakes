#!/usr/bin/env bash
# Restart DE components on hyprland reload

# Waybar
pkill -x waybar || true
launch-waybar &

# Notification daemon (swaync)
pkill -x swaync || true
sleep 0.2
swaync &

# Wallpaper
pkill -x hyprpaper || true
sleep 0.2
hyprpaper &

# XSettings daemon (for GTK/X11 apps)
pkill -x xsettingsd || true
sleep 0.1
xsettingsd &

# Idle management
pkill -x hypridle || true
sleep 0.2
hypridle &
