{
  config,
  inputs,
  lib,
  myHostLib,
  ...
}:
let
  cfg = config.my;
  hostCfg = cfg.hosts.thinkpad;
  user = cfg.user.name;
  branches = myHostLib.resolveBranches {
    inherit cfg hostCfg;
    hostName = "thinkpad";
  };
in
{
  config.my.hosts.thinkpad = {
    system = "x86_64-linux";
    branches = [
      "desktop"
      "printing"
    ];
    nixosModules = [ ];
    hardwareModules = [
      inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p14s-amd-gen2
    ];
  };

  config.flake.nixosConfigurations.thinkpad = lib.nixosSystem {
    system = hostCfg.system;
    modules = [
      ./_hardware.nix
      {
        config.nixpkgs.config.permittedInsecurePackages = [
          "electron-39.8.10"
        ];
      }
      inputs.impermanence.nixosModules.impermanence
      inputs.home-manager.nixosModules.home-manager
      (
        { pkgs, ... }:
        {
          # RTL8852AE is stable without the old rtw89 ASPM/PS workarounds on kernel 7.x.
          # Restore them (plus TLP WIFI_PWR_ON_BAT="off") if the link misbehaves.

          networking = {
            hostName = "thinkpad";
          };

          # Unencrypted disk: random per-boot swap key (hibernation must stay off).
          # by-partuuid is mandatory — the UUID is erased on every boot.
          swapDevices = lib.mkForce [
            {
              device = "/dev/disk/by-partuuid/22f53553-15a6-42af-a045-1f79341e741e";
              randomEncryption.enable = true;
            }
          ];

          # No WoL: TLP WOL_DISABLE="Y" overrides systemd .link settings.
          # To enable, set WOL_DISABLE="N" in core/power.nix and restore the links.

          # ethtool/wakeonlan live in esprimo config where WoL is used.

          # eDP backlight dominates idle draw; cap at 40% on battery.
          # Only ever lowers brightness, so manual raises stick until next unplug.
          systemd.services.battery-brightness-cap = {
            description = "Cap panel brightness when running on battery";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = pkgs.writeShellScript "battery-brightness-cap" ''
                set -eu
                brightnessctl="${pkgs.brightnessctl}/bin/brightnessctl -c backlight"
                cap=$(( $($brightnessctl max) * 40 / 100 ))
                if [ "$($brightnessctl get)" -gt "$cap" ]; then
                  $brightnessctl set "$cap"
                fi
              '';
            };
          };

          services.udev.extraRules = ''
            SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{online}=="0", RUN+="${pkgs.systemd}/bin/systemctl --no-block start battery-brightness-cap.service"
          '';

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            # Back up (don't fail on) files HM takes over, e.g. mimeapps.list.
            backupFileExtension = "backup";
            extraSpecialArgs = { inherit inputs; };
            users.${user}.imports =
              branches.hmModules
              ++ hostCfg.hmModules
              ++ [
                inputs.hyprland.homeManagerModules.default
                (
                  { lib, ... }:
                  {
                    home = {
                      username = user;
                      homeDirectory = lib.mkForce "/home/${user}";
                      stateVersion = cfg.stateVersion;
                    };
                    programs.home-manager.enable = true;
                  }
                )
              ];
          };
        }
      )
    ]
    ++ branches.nixosModules
    ++ hostCfg.nixosModules
    ++ hostCfg.hardwareModules;
  };
}
