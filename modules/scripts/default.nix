{ pkgs, ... }:

let
  cava-internal = pkgs.writeShellScriptBin "cava-internal" ''
    cava -p ~/.config/cava/config1 | sed -u 's/;//g;s/0/▁/g;s/1/▂/g;s/2/▃/g;s/3/▄/g;s/4/▅/g;s/5/▆/g;s/6/▇/g;s/7/█/g;'
  '';
  wallpaper_random = pkgs.writeShellScriptBin "wallpaper_random" ''
    if command -v swww >/dev/null 2>&1; then 
        killall dynamic_wallpaper
        swww img $(find ~/Pictures/wallpaper/. -name "*.png" | shuf -n1) --transition-type random
    else 
        killall swaybg
        killall dynamic_wallpaper
        swaybg -i $(find ~/Pictures/wallpaper/. -name "*.png" | shuf -n1) -m fill &
    fi
  '';
  grimblast_watermark = pkgs.writeShellScriptBin "grimblast_watermark" ''
        FILE=$(date "+%Y-%m-%d"T"%H:%M:%S").png
    # Get the picture from maim
        grimblast --notify --cursor save area $HOME/Pictures/src.png >> /dev/null 2>&1
    # add shadow, round corner, border and watermark
        convert $HOME/Pictures/src.png \
          \( +clone -alpha extract \
          -draw 'fill black polygon 0,0 0,8 8,0 fill white circle 8,8 8,0' \
          \( +clone -flip \) -compose Multiply -composite \
          \( +clone -flop \) -compose Multiply -composite \
          \) -alpha off -compose CopyOpacity -composite $HOME/Pictures/output.png
    #
        convert $HOME/Pictures/output.png -bordercolor none -border 20 \( +clone -background black -shadow 80x8+15+15 \) \
          +swap -background transparent -layers merge +repage $HOME/Pictures/$FILE
    #
        composite -gravity Southeast "${./watermark.png}" $HOME/Pictures/$FILE $HOME/Pictures/$FILE 
    #
        wl-copy < $HOME/Pictures/$FILE
    #   remove the other pictures
        rm $HOME/Pictures/src.png $HOME/Pictures/output.png
  '';
  grimshot_watermark = pkgs.writeShellScriptBin "grimshot_watermark" ''
        FILE=$(date "+%Y-%m-%d"T"%H:%M:%S").png
    # Get the picture from maim
        grimshot --notify  save area $HOME/Pictures/src.png >> /dev/null 2>&1
    # add shadow, round corner, border and watermark
        convert $HOME/Pictures/src.png \
          \( +clone -alpha extract \
          -draw 'fill black polygon 0,0 0,8 8,0 fill white circle 8,8 8,0' \
          \( +clone -flip \) -compose Multiply -composite \
          \( +clone -flop \) -compose Multiply -composite \
          \) -alpha off -compose CopyOpacity -composite $HOME/Pictures/output.png
    #
        convert $HOME/Pictures/output.png -bordercolor none -border 20 \( +clone -background black -shadow 80x8+15+15 \) \
          +swap -background transparent -layers merge +repage $HOME/Pictures/$FILE
    #
        composite -gravity Southeast "${./watermark.png}" $HOME/Pictures/$FILE $HOME/Pictures/$FILE 
    #
    # # Send the Picture to clipboard
        wl-copy < $HOME/Pictures/$FILE
    #
    # # remove the other pictures
        rm $HOME/Pictures/src.png $HOME/Pictures/output.png
  '';
  flameshot_watermark = pkgs.writeShellScriptBin "flameshot_watermark" ''
        FILE=$(date "+%Y-%m-%d"T"%H:%M:%S").png

        flameshot gui -r > $HOME/Pictures/src.png
    # add shadow, round corner, border and watermark
    convert $HOME/Pictures/src.png \
    	\( +clone -alpha extract \
    	-draw 'fill black polygon 0,0 0,8 8,0 fill white circle 8,8 8,0' \
    	\( +clone -flip \) -compose Multiply -composite \
    	\( +clone -flop \) -compose Multiply -composite \
    	\) -alpha off -compose CopyOpacity -composite $HOME/Pictures/output.png

    convert $HOME/Pictures/output.png -bordercolor none -border 20 \( +clone -background black -shadow 80x8+15+15 \) \
    	+swap -background transparent -layers merge +repage $HOME/Pictures/$FILE

    composite -gravity Southeast "${./watermark.png}" $HOME/Pictures/$FILE $HOME/Pictures/$FILE
    if [[ "$XDG_CURRENT_DESKTOP"=="Hyprland" ]] || [[ "$XDG_CURRENT_DESKTOP"=="sway" ]];then 
      # # Send the Picture to clipboard
        wl-copy < $HOME/Pictures/$FILE
    else
    # Send the Picture to clipboard
        xclip -selection clipboard -t image/png -i $HOME/Pictures/$FILE
    fi

    # remove the other pictures
    rm $HOME/Pictures/src.png $HOME/Pictures/output.png
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
  # myi3lock = pkgs.writeShellScriptBin "myi3lock" ''
  # '';
  dynamic_wallpaper = pkgs.writeShellScriptBin "dynamic_wallpaper" ''
    if command -v swww >/dev/null 2>&1; then 
        swww img $(find ~/Pictures/wallpaper/. -name "*.png" | shuf -n1) --transition-type random
        OLD_PID=$!
        while true; do
            sleep 120
        swww img $(find ~/Pictures/wallpaper/. -name "*.png" | shuf -n1) --transition-type random
            NEXT_PID=$!
            sleep 5
            kill $OLD_PID
            OLD_PID=$NEXT_PID
        done
    elif command -v swaybg >/dev/null 2>&1; then  
        killall swaybg
        swaybg -i $(find ~/Pictures/wallpaper/. -name "*.png" | shuf -n1) -m fill &
        OLD_PID=$!
        while true; do
            sleep 120
            swaybg -i $(find ~/Pictures/wallpaper/. -name "*.png" | shuf -n1) -m fill &
            NEXT_PID=$!
            sleep 5
            kill $OLD_PID
            OLD_PID=$NEXT_PID
        done
    else 
        killall feh 
        feh --randomize --bg-fill $(find ~/Pictures/wallpaper/. -name "*.png" | shuf -n1) &
        OLD_PID=$!
        while true; do
            sleep 120
            feh --randomize --bg-fill $(find ~/Pictures/wallpaper/. -name "*.png" | shuf -n1) &
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
           if [[ "$GTK_THEME" == "Catppuccin-Frappe-Pink" ]]; then
             swww img "${../theme/catppuccin-dark/common/wall/default.png}" --transition-type random
           elif [[ "$GTK_THEME" == "Catppuccin-Latte-Green" ]]; then
             swww img "${../theme/catppuccin-light/common/wall/default.png}" --transition-type random
           fi
    elif command -v swaybg >/dev/null 2>&1; then 
        killall swaybg
        killall dynamic_wallpaper
        if [[ "$GTK_THEME" == "Catppuccin-Frappe-Pink" ]]; then
          swaybg -i "${../theme/catppuccin-dark/common/wall/default.png}" -m fill &
        elif [[ "$GTK_THEME" == "Catppuccin-Latte-Green" ]]; then
          swaybg -i "${../theme/catppuccin-light/common/wall/default.png}" -m fill &
        fi
    else 
        killall feh
        killall dynamic_wallpaper
        if [[ "$GTK_THEME" == "Catppuccin-Frappe-Pink" ]]; then
          feh --randomize --bg-fill "${../theme/catppuccin-dark/common/wall/default.png}" &
        elif [[ "$GTK_THEME" == "Catppuccin-Latte-Green" ]]; then
          feh --randomize --bg-fill "${../theme/catppuccin-light/common/wall/default.png}" &
        fi
    fi
  '';
  launch-waybar = pkgs.writeShellScriptBin "launch-waybar" ''
    killall .waybar-wrapped || true
    sleep 0.3

    SDIR="$HOME/.config/waybar"
    STATE_DIR="$HOME/.local/state/waybar"
    STATE_FILE="$STATE_DIR/waybar-theme.sh"
    DISABLED_FILE="$STATE_DIR/waybar-disabled"

    # If waybar is disabled, don't launch
    if [[ -f "$DISABLED_FILE" ]]; then
      exit 0
    fi

    # Default theme
    THEME_FOLDER="/nixos"
    VARIATION="/nixos/default"

    # Read saved theme if it exists
    if [[ -f "$STATE_FILE" ]]; then
      IFS=';' read -r THEME_FOLDER VARIATION < "$STATE_FILE"
    fi

    CONFIG="$SDIR/themes$THEME_FOLDER/config"
    STYLE="$SDIR/themes$VARIATION/style.css"

    # Fallback to nixos theme if selected theme is missing
    if [[ ! -f "$CONFIG" ]] || [[ ! -f "$STYLE" ]]; then
      THEME_FOLDER="/nixos"
      VARIATION="/nixos/default"
      CONFIG="$SDIR/themes$THEME_FOLDER/config"
      STYLE="$SDIR/themes$VARIATION/style.css"
    fi

    waybar -c "$CONFIG" -s "$STYLE" > /dev/null 2>&1 &
  '';
  waybar-themeswitcher = pkgs.writeShellScriptBin "waybar-themeswitcher" ''
    SDIR="$HOME/.config/waybar"
    STATE_DIR="$HOME/.local/state/waybar"
    STATE_FILE="$STATE_DIR/waybar-theme.sh"

    mkdir -p "$STATE_DIR"

    # Build list of available themes (variant dirs containing style.css)
    options=""
    while IFS= read -r css; do
      variant_dir="$(dirname "$css")"
      theme_dir="$(dirname "$variant_dir")"
      theme_name="$(basename "$theme_dir")/$(basename "$variant_dir")"

      # Source config.sh for display name if available
      display_name="$theme_name"
      if [[ -f "$variant_dir/config.sh" ]]; then
        source "$variant_dir/config.sh"
        display_name="$theme_name"
      fi

      options="$options$theme_name\n"
    done < <(find "$SDIR/themes" -mindepth 3 -name "style.css" -type f 2>/dev/null | sort)

    # Also check for themes where style.css is directly in the theme dir (themes-minimal)
    while IFS= read -r css; do
      theme_dir="$(dirname "$css")"
      parent="$(dirname "$theme_dir")"
      # Only include if this is a direct child of themes/ (not a variant)
      if [[ "$(basename "$parent")" == "themes" ]]; then
        theme_name="$(basename "$theme_dir")"
        # Only if there's no subdirs with style.css (i.e., it's a standalone theme)
        if ! find "$theme_dir" -mindepth 2 -name "style.css" -type f 2>/dev/null | grep -q .; then
          options="$options$theme_name\n"
        fi
      fi
    done < <(find "$SDIR/themes" -mindepth 2 -maxdepth 2 -name "style.css" -type f 2>/dev/null | sort)

    # Remove trailing newline and duplicates
    options=$(echo -e "$options" | sed '/^$/d' | sort -u)

    # Show rofi menu
    choice=$(echo -e "$options" | rofi -dmenu -replace -i -p "Waybar Theme" -config ~/.config/rofi/config-themes.rasi)

    if [[ -z "$choice" ]]; then
      exit 0
    fi

    # Determine theme folder and variation from choice
    if [[ "$choice" == */* ]]; then
      # Format: theme/variant (e.g., themes/default)
      theme_base="$(echo "$choice" | cut -d/ -f1)"
      variant="$(echo "$choice" | cut -d/ -f2)"
      THEME_FOLDER="/$theme_base"
      VARIATION="/$theme_base/$variant"
    else
      # Standalone theme (e.g., themes-minimal)
      THEME_FOLDER="/$choice"
      VARIATION="/$choice"
    fi

    # Save selection
    echo "$THEME_FOLDER;$VARIATION" > "$STATE_FILE"

    # Restart waybar with new theme
    launch-waybar
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
      if [[ "$GTK_THEME" == "Catppuccin-Frappe-Pink" ]]; then
        hyprctl keyword general:col.active_border rgb\(ffc0cb\) 
      elif [[ "$GTK_THEME" == "Catppuccin-Latte-Green" ]]; then
          hyprctl keyword general:col.active_border rgb\(C4ACEB\)
      else
          hyprctl keyword general:col.active_border rgb\(81a1c1\)
      fi
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
    waybar-themeswitcher
    waybar-toggle
    border_color
  ];
}
