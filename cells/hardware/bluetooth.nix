_: {
  config.my.branches.desktop.nixosModules = [
    (
      { pkgs, ... }:
      {
        hardware.bluetooth = {
          enable = true;
          powerOnBoot = false;
          settings = {
            General = {
              Enable = "Source,Sink,Media,Socket";
            };
          };
        };
        services.blueman.enable = true;

        # powerOnBoot=false never auto-powers; this unit restores BT on AC only.
        # Manual off on battery stays off.
        systemd.services.bluetooth-power-on = {
          description = "Power on the bluetooth controller when running on AC";
          # After resume so USB re-enumerates; retry covers firmware reload.
          after = [
            "bluetooth.service"
            "suspend.target"
          ];
          wants = [ "bluetooth.service" ];
          # Per systemd.special(7): resume units use After + WantedBy suspend.target.
          wantedBy = [ "suspend.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "bluetooth-power-on" ''
              set -eu
              PATH=${
                pkgs.lib.makeBinPath [
                  pkgs.bluez
                  pkgs.util-linux
                  pkgs.coreutils
                  pkgs.gnused
                ]
              }

              on_ac() {
                for supply in /sys/class/power_supply/*; do
                  if [ "$(cat "$supply/type" 2>/dev/null)" != Mains ]; then
                    continue
                  fi
                  if [ "$(cat "$supply/online" 2>/dev/null)" = 1 ]; then
                    return 0
                  fi
                done
                return 1
              }

              powered() {
                bluetoothctl show 2>/dev/null |
                  sed -n 's/^[[:space:]]*Powered:[[:space:]]*//p' |
                  head -n1 || true
              }

              if ! on_ac; then
                exit 0
              fi

              rfkill unblock bluetooth
              # Retry ~10s for post-resume RTL firmware reload.
              i=0
              while [ "$i" -lt 20 ]; do
                bluetoothctl power on >/dev/null 2>&1 || true
                if [ "$(powered)" = yes ]; then
                  exit 0
                fi
                sleep 0.5
                i=$((i + 1))
              done

              echo "bluetooth-power-on: controller did not power on" >&2
              exit 1
            '';
          };
        };

        # KERNEL=="AC" is the ThinkPad mains supply; other machines never fire.
        # Panel-backlight off rule lives in the thinkpad host config.
        services.udev.extraRules = ''
          SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{online}=="1", RUN+="${pkgs.systemd}/bin/systemctl --no-block start bluetooth-power-on.service"
        '';
      }
    )
  ];
}
