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

        # powerOnBoot = false writes Policy.AutoEnable = false, so bluetoothd
        # never powers the controller by itself.  That is right on battery, but
        # wrong with the charger in: the bluetooth mouse has to be back the
        # moment the machine is usable again.  Hence this unit, on the charger
        # arriving and on resume.
        #
        # It only ever powers the controller *on*, and only on AC, so turning
        # bluetooth off by hand on battery stays off.
        systemd.services.bluetooth-power-on = {
          description = "Power on the bluetooth controller when running on AC";
          # Ordered after the resume so the USB controller has re-enumerated;
          # the retry loop below covers the firmware reload that follows.
          after = [
            "bluetooth.service"
            "suspend.target"
          ];
          wants = [ "bluetooth.service" ];
          # systemd.special(7): a unit that should run on resume orders itself
          # After= suspend.target and installs itself WantedBy= it.
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
              # Up to ~10s: after a resume the RTL firmware reload has to finish
              # before bluez will accept the controller.
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

        # KERNEL=="AC" is the ThinkPad's mains supply; machines without one
        # simply never fire this.  The matching online=="0" rule for the panel
        # backlight lives in the thinkpad host config.
        services.udev.extraRules = ''
          SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{online}=="1", RUN+="${pkgs.systemd}/bin/systemctl --no-block start bluetooth-power-on.service"
        '';
      }
    )
  ];
}
