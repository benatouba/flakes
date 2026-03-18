#!/usr/bin/env bash
# Set a random wallpaper from ~/pictures/wallpaper/ via hyprpaper
WALLPAPER_DIR="$HOME/pictures/wallpaper"

# Pick a random image
WALLPAPER=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | shuf -n 1)

if [ -z "$WALLPAPER" ]; then
    echo "No wallpapers found in $WALLPAPER_DIR" >&2
    exit 1
fi

# Unload all current wallpapers, preload new one, set it on all monitors
hyprctl hyprpaper unload all
hyprctl hyprpaper preload "$WALLPAPER"

# Apply to all connected monitors
for monitor in $(hyprctl monitors -j | jq -r '.[].name'); do
    hyprctl hyprpaper wallpaper "$monitor,$WALLPAPER"
done
