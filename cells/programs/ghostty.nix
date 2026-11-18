# Ghostty is the default desktop terminal; shpool keeps shells alive across
# closed windows (Ghostty has no mux). WezTerm stays installed as a fallback
# (wezterm.nix). Colors come from catppuccin.ghostty in cells/theme.
{ config, ... }:
let
  inherit (config.my) theme;
in
{
  config.my.branches.desktop.hmModules = [
    (
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        ghostty = lib.getExe config.programs.ghostty.package;
        shpool = lib.getExe config.services.shpool.package;

        # ghostty-session        attach the most recently detached session, else a new tN
        # ghostty-session pick   open a window with an fzf picker over the sessions
        # Windows open through `+new-window`, so the systemd-run instance serves them.
        sessionLauncher = pkgs.writeShellApplication {
          name = "ghostty-session";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.fzf
            pkgs.gnugrep
            pkgs.jq
          ];
          text = ''
            sessions() {
              ${shpool} list --json 2>/dev/null || echo '{"sessions": []}'
            }

            latest_detached() {
              sessions | jq -r '
                [.sessions[] | select(.status == "Disconnected")]
                | max_by(.last_disconnected_at_unix_ms) | .name // empty'
            }

            next_name() {
              local names n=1
              names=$(sessions | jq -r '.sessions[].name')
              while grep -qxF "t$n" <<<"$names"; do
                n=$((n + 1))
              done
              echo "t$n"
            }

            window() {
              exec ${ghostty} +new-window -e "$@"
            }

            choose() {
              local new="[new session]" choice name
              choice=$(
                {
                  echo "$new"
                  sessions | jq -r '.sessions[] | "\(.name)\t\(.status)"'
                } | fzf --prompt='shpool> ' --delimiter='\t'
              ) || exit 0
              name=''${choice%%$'\t'*}
              if [[ $name == "$new" ]]; then
                name=$(next_name)
              fi
              # The pick is explicit, so take the session over from another window.
              exec ${shpool} attach --force "$name"
            }

            case "''${1:-}" in
              "")
                name=$(latest_detached)
                window ${shpool} attach "''${name:-$(next_name)}"
                ;;
              pick) window "$(readlink -f "$0")" choose ;;
              choose) choose ;;
              *)
                echo "usage: ghostty-session [pick]" >&2
                exit 2
                ;;
            esac
          '';
        };
      in
      {
        programs.ghostty = {
          enable = true;
          # Keeps the app running so new windows open fast (+new-window over D-Bus).
          systemd.enable = true;
          enableZshIntegration = true;
          settings = {
            font-family = [
              theme.font.mono
              "Fira Code"
              "Noto Color Emoji"
              "Noto Emoji"
              "Noto Sans Symbols"
              "DejaVu Sans Mono"
            ];
            font-feature = [
              "calt"
              "clig"
              "liga"
            ];
            background-opacity = 0.95;
            window-decoration = "none";
            window-show-tab-bar = "never";
            bell-features = "no-audio,no-system";
            scrollbar = "system";
            # Same history as WezTerm's scrollback_lines; the default byte cap still applies.
            scrollback-limit-lines = 3500;
            keybind = [ "ctrl+shift+w=close_surface" ];
            confirm-close-surface = true;
            term = "xterm-ghostty";
            # ssh presents xterm-256color remotely; remote hosts stay untouched.
            shell-integration-features = "ssh-env,no-ssh-terminfo";
          };
        };

        services.shpool = {
          enable = true;
          settings = {
            # The attach client runs inside Ghostty, but the daemon starts the
            # shell; forward Ghostty's env so its zsh integration loads there.
            forward_env = [
              "TERM"
              "TERM_PROGRAM"
              "TERM_PROGRAM_VERSION"
              "GHOSTTY_RESOURCES_DIR"
              "GHOSTTY_SHELL_FEATURES"
              "COLORTERM"
            ];
            prompt_prefix = "";
          };
        };

        home.packages = [ sessionLauncher ];
      }
    )
  ];
}
