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
        # Not persisted, and it does not need to be: hyprpaper's ExecStartPre
        # repopulates it on every login.
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

        # hyprpaper 0.8 dropped preload/unload/reload from its IPC; the only
        # requests left are `wallpaper` and `listactive`.  The IPC part is
        # skipped when hyprpaper is not reachable so this also works as its
        # ExecStartPre, where only the symlink matters.
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

        # Deletes the image behind the `current` symlink and moves on to a
        # new random one - for weeding the pool from the keyboard.  The
        # realpath check is the only guard: the symlink is user-writable, so
        # never rm anything that does not resolve into the pool.
        wallpaper_delete_current = pkgs.writeShellScriptBin "wallpaper_delete_current" ''
          set -eu
          target=$(readlink -f ${current} 2>/dev/null || true)
          case "$target" in
              ${pool}/?*) ;;
              *)
                  ${pkgs.libnotify}/bin/notify-send -u critical "Wallpaper" "Not deleting: ''${target:-<none>} is outside ${pool}"
                  exit 1
                  ;;
          esac
          rm -f -- "$target" ${current}
          # Do not leave the lock screen pointing at a file that is gone.
          if [ "$(readlink -f ${lock} 2>/dev/null || true)" = "$target" ]; then
              rm -f ${lock}
          fi
          ${pkgs.libnotify}/bin/notify-send "Wallpaper" "Deleted $(basename "$target")"
          exec ${wallpaper_random}/bin/wallpaper_random
        '';

        # hyprlock reads its background path once at startup, so a fresh
        # random pick per lock is just a symlink update before exec.
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

        # A new random pick on every login.  Doing it in ExecStartPre instead
        # of a separate oneshot ordered After=hyprpaper.service avoids the
        # ordering cycle the old random-wallpaper.service created with
        # graphical-session.target (systemd dropped the job every login, so
        # the wallpaper never changed).  It also needs no IPC: hyprpaper just
        # reads the symlink when it starts.
        systemd.user.services.hyprpaper.Service.ExecStartPre = "${wallpaper_random}/bin/wallpaper_random";

        # The path is a symlink hyprpaper resolves at load time; monitor is
        # left empty so it applies to every output, docked or not.
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
