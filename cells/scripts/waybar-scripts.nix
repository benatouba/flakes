{ config, ... }:
let
  theme = config.my.theme;
in
{
  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      let
        # Where launch-waybar used to compute these at runtime, they are now
        # resolved once here and baked into the unit.
        waybarDir = "%h/.config/waybar/themes/catppuccin";
        waybarConfig = "${waybarDir}/config";
        waybarStyle = "${waybarDir}/${theme.waybarVariation}/style.css";

        # Toggling the bar is now starting and stopping a unit, so the
        # ~/.local/state/waybar/waybar-disabled sentinel is gone: systemd
        # already knows whether waybar is running, and the old script had to
        # keep the file and the process agreeing by hand.
        waybar-toggle = pkgs.writeShellApplication {
          name = "waybar-toggle";
          runtimeInputs = [ pkgs.systemd ];
          text = ''
            if systemctl --user --quiet is-active waybar.service; then
              systemctl --user stop waybar.service
            else
              systemctl --user start waybar.service
            fi
          '';
        };

        # The waybar bluetooth menu used to call `rfkill unblock bluetooth`,
        # which only clears a soft block. Nothing blocks the radio at boot, so
        # "Turn on" was a no-op while the controller itself stayed unpowered:
        # hardware.bluetooth.powerOnBoot = false writes Policy.AutoEnable =
        # false, so bluetoothd never powers a controller on its own. Powering it
        # is a bluez operation, hence bluetoothctl; rfkill stays in the picture
        # because the ThinkPad's radio kill switch works through it.
        bluetooth-power = pkgs.writeShellApplication {
          name = "bluetooth-power";
          runtimeInputs = with pkgs; [
            bluez
            util-linux
            coreutils
            gnused
          ];
          text = ''
            powered() {
              bluetoothctl show 2>/dev/null |
                sed -n 's/^[[:space:]]*Powered:[[:space:]]*//p' |
                head -n1 || true
            }

            case "''${1:-toggle}" in
              on) want=yes ;;
              off) want=no ;;
              toggle) if [ "$(powered)" = yes ]; then want=no; else want=yes; fi ;;
              *)
                echo "usage: bluetooth-power [on|off|toggle]" >&2
                exit 2
                ;;
            esac

            if [ "$want" = yes ]; then
              # Unblock first: bluez refuses to power a blocked controller, and
              # it needs a moment to pick the controller back up afterwards.
              rfkill unblock bluetooth
              for _ in {1..10}; do
                bluetoothctl power on >/dev/null 2>&1 || true
                if [ "$(powered)" = yes ]; then exit 0; fi
                sleep 0.2
              done
              echo "bluetooth-power: controller did not power on" >&2
              exit 1
            fi

            # Power down before blocking, so connected devices see a clean
            # disconnect instead of the radio vanishing under them.
            bluetoothctl power off >/dev/null 2>&1 || true
            rfkill block bluetooth
          '';
        };

        cava-internal = pkgs.writeShellScriptBin "cava-internal" ''
          cava -p ~/.config/cava/config1 | sed -u 's/;//g;s/0/▁/g;s/1/▂/g;s/2/▃/g;s/3/▄/g;s/4/▅/g;s/5/▆/g;s/6/▇/g;s/7/█/g;'
        '';
      in
      {
        # Not home-manager's `programs.waybar`: its unit runs waybar with no
        # arguments, which expects ~/.config/waybar/{config,style.css}. This
        # repo keeps them under themes/catppuccin/ and picks the stylesheet
        # from theme.waybarVariation, so the unit is written out here instead.
        # cells/desktop/waybar.nix still installs plain nixpkgs waybar, for the
        # binary-cache reason documented there.
        systemd.user.services.waybar = {
          Unit = {
            Description = "Waybar";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
            # Tray modules need somewhere to put icons.
            Requires = [ "tray.target" ];
          };
          Service = {
            ExecStart = "${pkgs.waybar}/bin/waybar -c ${waybarConfig} -s ${waybarStyle}";
            ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
            Restart = "on-failure";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };

        home.packages = [
          waybar-toggle
          bluetooth-power
          cava-internal
        ];
      }
    )
  ];
}
