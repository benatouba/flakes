{ pkgs, theme ? "dark", ... }:

let
  # Resolve theme-dependent values at build time
  wallpaperPath = if theme == "light"
    then ../theme/catppuccin-light/common/wall/default.png
    else ../theme/catppuccin-dark/common/wall/default.png;
  waybarVariation = if theme == "light" then "latte" else "mocha";
  borderColorHex = if theme == "light" then "C4ACEB" else "ffc0cb";

  cava-internal = pkgs.writeShellScriptBin "cava-internal" ''
    cava -p ~/.config/cava/config1 | sed -u 's/;//g;s/0/▁/g;s/1/▂/g;s/2/▃/g;s/3/▄/g;s/4/▅/g;s/5/▆/g;s/6/▇/g;s/7/█/g;'
  '';
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
  grimblast_watermark = pkgs.writeShellScriptBin "grimblast_watermark" ''
        FILE=$(date "+%Y-%m-%d"T"%H:%M:%S").png
    # Get the picture from maim
        grimblast --notify --cursor save area $HOME/pictures/src.png >> /dev/null 2>&1
    # add shadow, round corner, border and watermark
        convert $HOME/pictures/src.png \
          \( +clone -alpha extract \
          -draw 'fill black polygon 0,0 0,8 8,0 fill white circle 8,8 8,0' \
          \( +clone -flip \) -compose Multiply -composite \
          \( +clone -flop \) -compose Multiply -composite \
          \) -alpha off -compose CopyOpacity -composite $HOME/pictures/output.png
    #
        convert $HOME/pictures/output.png -bordercolor none -border 20 \( +clone -background black -shadow 80x8+15+15 \) \
          +swap -background transparent -layers merge +repage $HOME/pictures/$FILE
    #
        composite -gravity Southeast "${./watermark.png}" $HOME/pictures/$FILE $HOME/pictures/$FILE
    #
        wl-copy < $HOME/pictures/$FILE
    #   remove the other pictures
        rm $HOME/pictures/src.png $HOME/pictures/output.png
  '';
  grimshot_watermark = pkgs.writeShellScriptBin "grimshot_watermark" ''
        FILE=$(date "+%Y-%m-%d"T"%H:%M:%S").png
    # Get the picture from maim
        grimshot --notify  save area $HOME/pictures/src.png >> /dev/null 2>&1
    # add shadow, round corner, border and watermark
        convert $HOME/pictures/src.png \
          \( +clone -alpha extract \
          -draw 'fill black polygon 0,0 0,8 8,0 fill white circle 8,8 8,0' \
          \( +clone -flip \) -compose Multiply -composite \
          \( +clone -flop \) -compose Multiply -composite \
          \) -alpha off -compose CopyOpacity -composite $HOME/pictures/output.png
    #
        convert $HOME/pictures/output.png -bordercolor none -border 20 \( +clone -background black -shadow 80x8+15+15 \) \
          +swap -background transparent -layers merge +repage $HOME/pictures/$FILE
    #
        composite -gravity Southeast "${./watermark.png}" $HOME/pictures/$FILE $HOME/pictures/$FILE
    #
    # # Send the picture to clipboard
        wl-copy < $HOME/pictures/$FILE
    #
    # # remove the other pictures
        rm $HOME/pictures/src.png $HOME/pictures/output.png
  '';
  flameshot_watermark = pkgs.writeShellScriptBin "flameshot_watermark" ''
        FILE=$(date "+%Y-%m-%d"T"%H:%M:%S").png

        flameshot gui -r > $HOME/pictures/src.png
    # add shadow, round corner, border and watermark
    convert $HOME/pictures/src.png \
    	\( +clone -alpha extract \
    	-draw 'fill black polygon 0,0 0,8 8,0 fill white circle 8,8 8,0' \
    	\( +clone -flip \) -compose Multiply -composite \
    	\( +clone -flop \) -compose Multiply -composite \
    	\) -alpha off -compose CopyOpacity -composite $HOME/pictures/output.png

    convert $HOME/pictures/output.png -bordercolor none -border 20 \( +clone -background black -shadow 80x8+15+15 \) \
    	+swap -background transparent -layers merge +repage $HOME/pictures/$FILE

    composite -gravity Southeast "${./watermark.png}" $HOME/pictures/$FILE $HOME/pictures/$FILE
    if [[ "$XDG_CURRENT_DESKTOP"=="Hyprland" ]] || [[ "$XDG_CURRENT_DESKTOP"=="sway" ]];then
      # # Send the picture to clipboard
        wl-copy < $HOME/pictures/$FILE
    else
    # Send the picture to clipboard
        xclip -selection clipboard -t image/png -i $HOME/pictures/$FILE
    fi

    # remove the other pictures
    rm $HOME/pictures/src.png $HOME/pictures/output.png
  '';
  myswaylock = pkgs.writeShellScriptBin "myswaylock" ''
    swaylock  \
           --screenshots \
           --clock \
           --indicator \
           --indicator-radius 100 \
           --indicator-thickness 7 \
           --effect-blur 7x5 \
           --effect-vignette 0.5:0.5 \
           --ring-color 3b4252 \
           --key-hl-color 880033 \
           --line-color 00000000 \
           --inside-color 00000088 \
           --separator-color 00000000 \
           --grace 2 \
           --fade-in 0.3
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
  launch-waybar = pkgs.writeShellScriptBin "launch-waybar" ''
    SDIR="$HOME/.config/waybar"
    STATE_DIR="$HOME/.local/state/waybar"
    DISABLED_FILE="$STATE_DIR/waybar-disabled"

    mkdir -p "$STATE_DIR"

    [[ -f "$DISABLED_FILE" ]] && exit 0

    CONFIG="$SDIR/themes/catppuccin/config"
    STYLE="$SDIR/themes/catppuccin/${waybarVariation}/style.css"

    if [[ ! -f "$CONFIG" || ! -f "$STYLE" ]]; then
      CONFIG="$SDIR/themes/default/config"
      STYLE="$SDIR/themes/default/style.css"
    fi

    pkill -x .waybar-wrapped 2>/dev/null || true
    pkill -x waybar 2>/dev/null || true
    waybar -c "$CONFIG" -s "$STYLE" >/dev/null 2>&1 &
  '';
  waybar-toggle = pkgs.writeShellScriptBin "waybar-toggle" ''
    STATE_DIR="$HOME/.local/state/waybar"
    DISABLED_FILE="$STATE_DIR/waybar-disabled"

    mkdir -p "$STATE_DIR"

    if [[ -f "$DISABLED_FILE" ]]; then
      rm "$DISABLED_FILE"
      launch-waybar
    else
      touch "$DISABLED_FILE"
      killall .waybar-wrapped 2>/dev/null
    fi
  '';
  border_color = pkgs.writeShellScriptBin "border_color" ''
    function border_color {
      hyprctl keyword general:col.active_border rgb\(${borderColorHex}\)
    }

    socat - UNIX-CONNECT:/tmp/hypr/$(echo $HYPRLAND_INSTANCE_SIGNATURE)/.socket2.sock | while read line; do border_color $line; done
  '';
in
{
  home.packages = [
    cava-internal
    wallpaper_random
    grimshot_watermark
    grimblast_watermark
    flameshot_watermark
    myswaylock
    dynamic_wallpaper
    default_wall
    launch-waybar
    waybar-toggle
    border_color
  ];
}
