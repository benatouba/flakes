{ pkgs, theme, ... }:

let
  wallpaperPath = ../../../dotfiles/wallpapers/${theme.slug}.png;

  wallpaper_random = pkgs.writeShellScriptBin "wallpaper_random" ''
    if command -v swww >/dev/null 2>&1; then
        killall dynamic_wallpaper
        swww img $(find ~/pictures/wallpaper/. -name "*.png" | shuf -n1) --transition-type random
    else
        killall swaybg
        killall dynamic_wallpaper
        swaybg -i $(find ~/pictures/wallpaper/. -name "*.png" | shuf -n1) -m fill &
    fi
  '';

  dynamic_wallpaper = pkgs.writeShellScriptBin "dynamic_wallpaper" ''
    if command -v swww >/dev/null 2>&1; then
        swww img $(find ~/pictures/wallpaper/. -name "*.png" | shuf -n1) --transition-type random
        OLD_PID=$!
        while true; do
            sleep 120
        swww img $(find ~/pictures/wallpaper/. -name "*.png" | shuf -n1) --transition-type random
            NEXT_PID=$!
            sleep 5
            kill $OLD_PID
            OLD_PID=$NEXT_PID
        done
    elif command -v swaybg >/dev/null 2>&1; then
        killall swaybg
        swaybg -i $(find ~/pictures/wallpaper/. -name "*.png" | shuf -n1) -m fill &
        OLD_PID=$!
        while true; do
            sleep 120
            swaybg -i $(find ~/pictures/wallpaper/. -name "*.png" | shuf -n1) -m fill &
            NEXT_PID=$!
            sleep 5
            kill $OLD_PID
            OLD_PID=$NEXT_PID
        done
    else
        killall feh
        feh --randomize --bg-fill $(find ~/pictures/wallpaper/. -name "*.png" | shuf -n1) &
        OLD_PID=$!
        while true; do
            sleep 120
            feh --randomize --bg-fill $(find ~/pictures/wallpaper/. -name "*.png" | shuf -n1) &
            NEXT_PID=$!
            sleep 5
            kill $OLD_PID
            OLD_PID=$NEXT_PID
        done
    fi
  '';

  default_wall = pkgs.writeShellScriptBin "default_wall" ''
    if command -v swww >/dev/null 2>&1; then
        killall dynamic_wallpaper
        swww img "${wallpaperPath}" --transition-type random
    elif command -v swaybg >/dev/null 2>&1; then
        killall swaybg
        killall dynamic_wallpaper
        swaybg -i "${wallpaperPath}" -m fill &
    else
        killall feh
        killall dynamic_wallpaper
        feh --randomize --bg-fill "${wallpaperPath}" &
    fi
  '';
in
{
  home.packages = [
    wallpaper_random
    dynamic_wallpaper
    default_wall
  ];
}
