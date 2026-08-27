{ config, lib, ... }:
let
  theme = config.my.theme;
  wallpaperPath = ../../dotfiles/wallpapers/${theme.slug}.png;
in
{
  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      let
        # The Omarchy theme wallpapers join the pool when the shell is enabled.
        # They are flattened into a single directory precisely so that
        # -maxdepth 1 still reaches them; see pkgs/omarchy-wallpapers.
        wallpaperRoots = lib.concatStringsSep " " (
          [ "~/pictures/wallpaper" ]
          ++ lib.optional config.my.enableOmarchyShell "${pkgs.omarchy-wallpapers}/share/omarchy/wallpapers"
        );

        pick_random = ''find ${wallpaperRoots} -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null | shuf -n1'';

        set_wallpaper = pkgs.writeShellScriptBin "set_wallpaper" ''
          IMG="$1"
          if [ -z "$IMG" ]; then
              echo "Usage: set_wallpaper <path>" >&2
              exit 1
          fi
          if command -v swww >/dev/null 2>&1; then
              swww img "$IMG" --transition-type grow --transition-duration 2
          else
              hyprctl hyprpaper unload all
              hyprctl hyprpaper preload "$IMG"
              for monitor in $(hyprctl monitors -j | jq -r '.[].name'); do
                  hyprctl hyprpaper wallpaper "$monitor,$IMG"
              done
          fi
        '';

        wallpaper_random = pkgs.writeShellScriptBin "wallpaper_random" ''
          killall dynamic_wallpaper 2>/dev/null
          IMG=$(${pick_random})
          [ -z "$IMG" ] && { echo "No wallpapers found" >&2; exit 1; }
          set_wallpaper "$IMG"
        '';

        dynamic_wallpaper = pkgs.writeShellScriptBin "dynamic_wallpaper" ''
          while true; do
              IMG=$(${pick_random})
              [ -n "$IMG" ] && set_wallpaper "$IMG"
              sleep 120
          done
        '';

        default_wall = pkgs.writeShellScriptBin "default_wall" ''
          killall dynamic_wallpaper 2>/dev/null
          set_wallpaper "${wallpaperPath}"
        '';
      in
      {
        home.packages = [
          set_wallpaper
          wallpaper_random
          dynamic_wallpaper
          default_wall
        ];
      }
    )
  ];
}
