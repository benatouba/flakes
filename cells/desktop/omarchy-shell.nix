# Omarchy 4 ("Quattro") Quickshell bar, OSD and notification daemon.
#
# Gated on my.enableOmarchyShell (default false). When enabled it replaces
# Waybar and swaync — see cells/desktop/waybar.nix and
# cells/desktop/notifications.nix, which gate themselves off on the same flag —
# and leaves rofi, hyprlock, hypridle, wlogout and hyprpaper alone. Turning the
# flag back off restores the previous desktop on the next rebuild.
#
# The vendored QML slice and its helper-script allowlist live in
# pkgs/omarchy-shell/default.nix. Before bumping the `omarchy` flake input,
# re-derive the script closure from upstream:
#
#   grep -rhoE '\bomarchy-[a-z0-9-]+' <vendored shell dirs>
#
# and confirm nothing new reaches pacman, snapper or limine.
{ config, lib, ... }:
let
  inherit (config.my) omarchyTheme;

  # Upstream's default layout minus everything backed by a plugin we do not
  # ship: omarchy.menu (needs pacman-aware helpers), omarchy.weather,
  # omarchy.system-update and omarchy.agents. Indicators are pinned to Dnd
  # because Dictation, ScreenRecording and Reminder need helper scripts we
  # dropped, and NightLight/StayAwake need the nightlight and idle services.
  shellSettings = {
    version = 1;
    bar = {
      id = "omarchy.bar";
      position = "top";
      transparent = false;
      centerAnchor = "omarchy.clock";
      layout = {
        left = [
          { id = "omarchy.workspaces"; }
          { id = "omarchy.active-window"; }
        ];
        center = [
          {
            id = "omarchy.indicators";
            # Dictation, ScreenRecording and Reminder need helper scripts we do
            # not ship; StayAwake needs the idle service, which stays with
            # hypridle. NightLight resolves now that the nightlight service is
            # vendored.
            items = [
              "NightLight"
              "Dnd"
            ];
          }
          {
            id = "omarchy.clock";
            format = "dddd HH:mm";
            formatAlt = "d MMMM 'W'ww yyyy";
          }
          { id = "omarchy.keyboard-layout"; }
          { id = "omarchy.media"; }
        ];
        right = [
          { id = "omarchy.tray"; }
          { id = "omarchy.bluetooth"; }
          { id = "omarchy.microphone"; }
          { id = "omarchy.network"; }
          { id = "omarchy.audio"; }
          { id = "omarchy.monitor"; }
          { id = "omarchy.power"; }
        ];
      };
    };
    # Idle and locking stay with hypridle/hyprlock, so the shell's own timings
    # are deliberately absent.
    plugins = [ ];
  };
in
{
  config.my.branches.desktop = {
    nixosModules = lib.optionals config.my.enableOmarchyShell [
      (
        { ... }:
        {
          # The power widget and battery service read battery state over
          # UPower's D-Bus interface. TLP handles power management here
          # (cells/core/power.nix) and does not pull UPower in on its own.
          services.upower.enable = true;
        }
      )
    ];

    hmModules = lib.optionals config.my.enableOmarchyShell [
      (
        { pkgs, ... }:
        let
          tomlFormat = pkgs.formats.toml { };

          # The shell draws every label and icon in one family. Point it at the
          # theme's mono font instead of the fontconfig "monospace" alias, which
          # cells/hardware/fonts.nix resolves to Noto Sans Mono CJK SC here.
          omarchy-shell = pkgs.omarchy-shell.override {
            fontFamily = config.my.theme.font.mono;
          };

          # Upstream's launch helpers go through uwsm-app and
          # xdg-terminal-exec, neither of which exists here, so the two the
          # bar and network panel call are reimplemented over wezterm. Same
          # CLI shape, so the QML needs no patching.
          launchOrFocusTui = pkgs.writeShellApplication {
            name = "omarchy-launch-or-focus-tui";
            runtimeInputs = with pkgs; [
              hyprland
              jq
              wezterm
            ];
            text = ''
              appId="org.omarchy.$(basename "$1")"
              if [[ ''${1:-} == --app-id=* ]]; then
                appId="''${1#--app-id=}"
                shift
              fi

              address=$(hyprctl clients -j \
                | jq -r --arg id "$appId" '.[] | select(.class == $id) | .address' \
                | head -n1)

              if [[ -n $address ]]; then
                exec hyprctl dispatch focuswindow "address:$address"
              fi

              exec setsid wezterm start --class "$appId" -- "$@"
            '';
          };

          launchFloatingTerminal = pkgs.writeShellApplication {
            name = "omarchy-launch-floating-terminal-with-presentation";
            runtimeInputs = [ pkgs.wezterm ];
            text = ''
              exec setsid wezterm start --class org.omarchy.terminal -- \
                bash -c "$*; printf '\nPress any key to close.'; read -r -n1"
            '';
          };
        in
        {
          home.packages = [
            omarchy-shell
            pkgs.omarchy-wallpapers
            launchOrFocusTui
            launchFloatingTerminal
          ];

          xdg.configFile."omarchy/shell.json" = {
            # The shell rewrites this file whenever a widget is dragged in the
            # bar, and upstream never merges defaults back in. Nix stays
            # authoritative: in-shell layout edits are discarded on the next
            # rebuild, and the layout above is the place to change it.
            force = true;
            source = pkgs.writeText "omarchy-shell.json" (builtins.toJSON shellSettings);
          };

          home.file = {
            ".local/state/omarchy/current/theme/colors.toml".source =
              tomlFormat.generate "omarchy-colors.toml" omarchyTheme.colorsToml;
            ".local/state/omarchy/current/theme/shell.toml".source =
              tomlFormat.generate "omarchy-shell.toml" omarchyTheme.shell;
          };
        }
      )
    ];
  };

  # So the package can be built and inspected on its own, without evaluating a
  # whole host: nix build .#omarchy-shell
  config.perSystem =
    { pkgs, ... }:
    {
      packages.omarchy-shell = pkgs.omarchy-shell;
    };
}
