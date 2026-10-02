{ config, ... }:
let
  theme = config.my.theme;
  fallbackWallpaper = ../../dotfiles/wallpapers/${theme.slug}.png;
in
{
  config.my.branches.desktop.hmModules = [
    (
      { config, pkgs, ... }:
      let
        pool = "${config.home.homeDirectory}/pictures/wallpaper";
        # Not persisted: hyprpaper ExecStartPre repopulates it each login.
        stateDir = "${config.home.homeDirectory}/.cache/wallpaper";
        current = "${stateDir}/current";
        lock = "${stateDir}/lock";

        pick_random = ''
          IMG=$(find ${pool} -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | shuf -n1)
          if [ -z "$IMG" ]; then
              echo "No wallpapers in ${pool}, using the theme default" >&2
              IMG=${fallbackWallpaper}
          fi
        '';

        # hyprpaper 0.8 keeps only `wallpaper`/`listactive`; skips IPC when
        # unreachable so this also works as its ExecStartPre.
        set_wallpaper = pkgs.writeShellScriptBin "set_wallpaper" ''
          IMG="$1"
          if [ -z "$IMG" ]; then
              echo "Usage: set_wallpaper <path>" >&2
              exit 1
          fi
          mkdir -p ${stateDir}
          ln -sfn "$IMG" ${current}
          if hyprctl hyprpaper listactive >/dev/null 2>&1; then
              for monitor in $(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[].name'); do
                  hyprctl hyprpaper wallpaper "$monitor,$IMG"
              done
          fi
        '';

        wallpaper_random = pkgs.writeShellScriptBin "wallpaper_random" ''
          killall dynamic_wallpaper 2>/dev/null
          ${pick_random}
          ${set_wallpaper}/bin/set_wallpaper "$IMG"
        '';

        dynamic_wallpaper = pkgs.writeShellScriptBin "dynamic_wallpaper" ''
          while true; do
              ${pick_random}
              ${set_wallpaper}/bin/set_wallpaper "$IMG"
              sleep 120
          done
        '';

        default_wall = pkgs.writeShellScriptBin "default_wall" ''
          killall dynamic_wallpaper 2>/dev/null
          ${set_wallpaper}/bin/set_wallpaper "${fallbackWallpaper}"
        '';

        # Weeds the pool from the keyboard; only delete targets inside the pool.
        wallpaper_delete_current = pkgs.writeShellScriptBin "wallpaper_delete_current" ''
          set -eu
          # Prefer what hyprpaper actually displays (other tools may set the
          # wallpaper without updating ${current}); output is "monitor: path".
          target=$(hyprctl hyprpaper listactive 2>/dev/null | head -n1 | sed 's/^[^:]*: //' || true)
          if [ -z "$target" ]; then
              target=$(readlink -f ${current} 2>/dev/null || true)
          fi
          target=$(readlink -f -- "$target" 2>/dev/null || true)
          case "$target" in
              ${pool}/?*) ;;
              *)
                  ${pkgs.libnotify}/bin/notify-send -u critical "Wallpaper" "Not deleting: ''${target:-<none>} is outside ${pool}"
                  exit 1
                  ;;
          esac
          rm -f -- "$target" ${current}
          # Don't leave the lock screen pointing at a deleted file.
          if [ "$(readlink -f ${lock} 2>/dev/null || true)" = "$target" ]; then
              rm -f ${lock}
          fi
          ${pkgs.libnotify}/bin/notify-send "Wallpaper" "Deleted $(basename "$target")"
          exec ${wallpaper_random}/bin/wallpaper_random
        '';

        # hyprlock reads background once at startup; update symlink then exec.
        lock_screen = pkgs.writeShellScriptBin "lock_screen" ''
          mkdir -p ${stateDir}
          ${pick_random}
          ln -sfn "$IMG" ${lock}
          exec hyprlock "$@"
        '';
      in
      {
        home.packages = [
          set_wallpaper
          wallpaper_random
          dynamic_wallpaper
          default_wall
          wallpaper_delete_current
          lock_screen
        ];

        # Random pick in ExecStartPre; avoids the old oneshot ordering cycle.
        systemd.user.services.hyprpaper.Service.ExecStartPre = "${wallpaper_random}/bin/wallpaper_random";

        # Symlink resolved at load; empty monitor applies to every output.
        xdg.configFile."hypr/hyprpaper.conf".text = ''
          wallpaper {
              monitor =
              path = ${current}
              fit_mode = cover
          }

          splash = false
        '';
      }
    )
  ];
}
