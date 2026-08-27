{ config, lib, ... }:
let
  theme = config.my.theme;
in
{
  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      let
        launch-waybar = pkgs.writeShellScriptBin "launch-waybar" ''
          SDIR="$HOME/.config/waybar"
          STATE_DIR="$HOME/.local/state/waybar"
          DISABLED_FILE="$STATE_DIR/waybar-disabled"

          mkdir -p "$STATE_DIR"

          [[ -f "$DISABLED_FILE" ]] && exit 0

          CONFIG="$SDIR/themes/catppuccin/config"
          STYLE="$SDIR/themes/catppuccin/${theme.waybarVariation}/style.css"

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
            hyprctl keyword general:col.active_border rgb\(${theme.borderColor}\)
          }

          socat - UNIX-CONNECT:/tmp/hypr/$(echo $HYPRLAND_INSTANCE_SIGNATURE)/.socket2.sock | while read line; do border_color $line; done
        '';

        cava-internal = pkgs.writeShellScriptBin "cava-internal" ''
          cava -p ~/.config/cava/config1 | sed -u 's/;//g;s/0/▁/g;s/1/▂/g;s/2/▃/g;s/3/▄/g;s/4/▅/g;s/5/▆/g;s/6/▇/g;s/7/█/g;'
        '';

      in
      {
        home.packages = [
          border_color
          cava-internal
        ]
        # Both drive the waybar binary, which cells/desktop/waybar.nix only
        # installs on the non-Omarchy path. Without this they sit on PATH and
        # fail silently.
        ++ lib.optionals (!config.my.enableOmarchyShell) [
          launch-waybar
          waybar-toggle
        ];
      }
    )
  ];
}
