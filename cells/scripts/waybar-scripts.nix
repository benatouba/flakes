{ config, ... }:
let
  theme = config.my.theme;
in
{
  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      let
        # Paths resolved once here and baked into the unit.
        waybarDir = "%h/.config/waybar/themes/catppuccin";
        waybarConfig = "${waybarDir}/config";
        waybarStyle = "${waybarDir}/${theme.waybarVariation}/style.css";

        # Toggle starts/stops the unit; systemd tracks state, no sentinel file.
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

        # powerOnBoot=false leaves the controller unpowered; needs bluetoothctl.
        # rfkill stays for the ThinkPad radio kill switch.
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
              # Unblock first; bluez needs a moment to pick the controller back up.
              rfkill unblock bluetooth
              for _ in {1..10}; do
                bluetoothctl power on >/dev/null 2>&1 || true
                if [ "$(powered)" = yes ]; then exit 0; fi
                sleep 0.2
              done
              echo "bluetooth-power: controller did not power on" >&2
              exit 1
            fi

            # Power off before blocking for a clean device disconnect.
            bluetoothctl power off >/dev/null 2>&1 || true
            rfkill block bluetooth
          '';
        };

        cava-internal = pkgs.writeShellScriptBin "cava-internal" ''
          cava -p ~/.config/cava/config1 | sed -u 's/;//g;s/0/▁/g;s/1/▂/g;s/2/▃/g;s/3/▄/g;s/4/▅/g;s/5/▆/g;s/6/▇/g;s/7/█/g;'
        '';
      in
      {
        # Custom unit: HM programs.waybar can't use themes/catppuccin paths.
        # Binary stays plain nixpkgs (cache reason, see desktop/waybar.nix).
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
