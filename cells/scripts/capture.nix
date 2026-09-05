# Screen capture: screenshots, text extraction, colour picking and recording.
#
# Replaces the three `hyprshot` keybinds and the dead cells/scripts/screenshot.nix,
# and gives `hyprpicker` and `wf-recorder` — both installed, neither previously
# called from anywhere — their first call sites.
#
# Keybinds live in cells/desktop/hyprland.nix (the Print family).
#
# The shape follows cells/scripts/wallpaper.nix, except these use
# writeShellApplication rather than writeShellScriptBin: it pins every binary
# through runtimeInputs instead of inheriting whatever PATH the compositor
# happens to have, and runs shellcheck at build time.
_: {
  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      let
        # One definition of where captures land, shared by every command below.
        #
        # This replaces the HYPRSHOT_DIR export in dotfiles/zsh/export.zsh, which
        # only interactive zsh ever sourced — keybinds run under the compositor,
        # which never saw it, so captures were landing in $HOME. The directory is
        # also created by a tmpfiles rule in cells/desktop/environment.nix, but
        # mkdir -p here keeps the commands usable on their own.
        captureDir = ''
          dir="''${XDG_PICTURES_DIR:-$HOME/pictures}/screenshots"
          mkdir -p "$dir"
        '';

        # Freeze the screen behind the selection. Without this the content keeps
        # updating while you drag, so you aim at one thing and capture another.
        # hyprpicker's -r is literally "render (freeze) inactive displays"; -z
        # drops the zoom lens, which is for colour picking rather than framing.
        freezeScreen = ''
          freeze() {
            hyprpicker -r -z &
            freeze_pid=$!
            trap 'kill "$freeze_pid" 2>/dev/null || true' EXIT
            sleep 0.1
          }
        '';

        # Pressing the same key again while a picker is on screen should cancel
        # it, not stack a second one behind the first.
        cancelExisting = ''
          if pkill -x slurp 2>/dev/null; then
            exit 0
          fi
        '';

        capture-screenshot = pkgs.writeShellApplication {
          name = "capture-screenshot";
          runtimeInputs = with pkgs; [
            coreutils
            grim
            hyprland
            hyprpicker
            jq
            libnotify
            procps
            satty
            slurp
            wl-clipboard
            xdg-utils
          ];
          text = ''
            mode="''${1:-region}"

            ${cancelExisting}
            ${captureDir}
            ${freezeScreen}

            file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
            geometry=""

            case "$mode" in
              display)
                : # whole output, grim's default
                ;;
              window)
                # Restrict the picker to the windows on the active workspace, so
                # a click snaps to a window instead of needing a careful drag.
                workspace=$(hyprctl activeworkspace -j | jq -r '.id')
                rects=$(hyprctl clients -j | jq -r --argjson ws "$workspace" \
                  '.[] | select(.workspace.id == $ws and .hidden == false)
                       | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
                freeze
                geometry=$(printf '%s\n' "$rects" | slurp -r) || exit 0
                ;;
              region | *)
                freeze
                geometry=$(slurp) || exit 0
                ;;
            esac

            if [ -n "$geometry" ]; then
              grim -g "$geometry" "$file"
            else
              grim "$file"
            fi

            wl-copy --type image/png < "$file"

            # -A implies --wait, so this blocks until the toast is acted on or
            # expires, and prints the chosen action's name. Annotation is offered
            # rather than forced: most screenshots never need it.
            action=$(notify-send -a Screenshot -i "$file" \
              -A edit=Annotate -A open=Open \
              "Screenshot copied" "$(basename "$file")") || exit 0

            case "$action" in
              edit) satty --filename "$file" ;;
              open) xdg-open "$file" ;;
            esac
          '';
        };

        capture-text = pkgs.writeShellApplication {
          name = "capture-text";
          runtimeInputs = with pkgs; [
            coreutils
            grim
            hyprpicker
            libnotify
            procps
            slurp
            (tesseract.override {
              # The unscoped package carries every language's training data:
              # 1104 MB of closure against 126 MB for these two. Measured.
              # Matches input.kb_layout = "de,us" in cells/desktop/hyprland.nix.
              enableLanguages = [
                "eng"
                "deu"
              ];
            })
            wl-clipboard
          ];
          text = ''
            ${cancelExisting}
            ${freezeScreen}

            freeze
            geometry=$(slurp) || exit 0

            # --oem 1 is the LSTM engine only, --psm 6 assumes one uniform block
            # of text, and --dpi 300 is needed because grim writes no DPI hint,
            # which otherwise makes tesseract guess badly on small selections.
            text=$(grim -g "$geometry" - \
              | tesseract stdin stdout \
                  --oem 1 --psm 6 -l eng+deu --dpi 300 \
                  -c preserve_interword_spaces=1 2>/dev/null)

            if [ -z "''${text//[[:space:]]/}" ]; then
              notify-send -a Screenshot -u low "No text found" "Nothing recognisable in that selection"
              exit 1
            fi

            printf '%s' "$text" | wl-copy
            notify-send -a Screenshot "Text copied" "$text"
          '';
        };

        capture-color = pkgs.writeShellApplication {
          name = "capture-color";
          runtimeInputs = with pkgs; [
            hyprpicker
            libnotify
          ];
          # hyprpicker copies (-a) and notifies (-n) by itself, so this exists
          # only to give the binding one name alongside the others and to pin
          # the output format.
          text = ''
            exec hyprpicker -a -n -f hex -l "$@"
          '';
        };

        capture-record = pkgs.writeShellApplication {
          name = "capture-record";
          runtimeInputs = with pkgs; [
            coreutils
            hyprpicker
            libnotify
            procps
            slurp
            wf-recorder
          ];
          text = ''
            # SIGINT rather than SIGTERM: wf-recorder traps it to flush and close
            # the container. Killed any other way the file is unplayable.
            if pgrep -x wf-recorder >/dev/null; then
              pkill -INT -x wf-recorder
              notify-send -a Screenshot "Recording stopped" "Saved to the screenshots folder"
              exit 0
            fi

            ${cancelExisting}
            ${captureDir}
            ${freezeScreen}

            audio=()
            if [ "''${1:-}" = "--audio" ]; then
              audio=(--audio)
            fi

            freeze
            geometry=$(slurp) || exit 0
            # The freeze overlay has to go before recording starts, or it is what
            # gets recorded.
            kill "$freeze_pid" 2>/dev/null || true
            trap - EXIT

            file="$dir/$(date +%Y-%m-%d_%H-%M-%S).mp4"
            wf-recorder -g "$geometry" -f "$file" "''${audio[@]}" >/dev/null 2>&1 &

            notify-send -a Screenshot "Recording started" "Press the same key again to stop"
          '';
        };
      in
      {
        home.packages = [
          capture-screenshot
          capture-text
          capture-color
          capture-record
        ];
      }
    )
  ];
}
