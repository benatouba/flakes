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
    nixosModules = [
      (
        { pkgs, ... }:
        {
          programs.steam = {
            enable = true;
            protontricks.enable = true;
            extraCompatPackages = [ pkgs.proton-ge-bin ];
          };
        }
      )
    ];
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
          # NOTE: the RTL8852AE previously needed
          #   options rtw89_pci disable_aspm_l1=y disable_aspm_l1ss=y
          #   options rtw89_core disable_ps_mode=y
          # to stay stable.  Those were kernel 5.16-6.1 era workarounds and
          # together cost ~1.5-2 W by pinning the PCIe link out of L1 and the
          # radio out of power save.  Dropped on kernel 7.x — restore this
          # block (and TLP's WIFI_PWR_ON_BAT="off") if the link misbehaves.

          networking = {
            hostName = "thinkpad";
          };

          # The disk is not encrypted, so anything paged out to the swap
          # partition persists in the clear.  A random per-boot key closes that
          # without repartitioning.  Safe here only because hibernation is
          # already off (security.protectKernelImage forces nohibernate);
          # re-enabling hibernate means undoing this first.
          # by-partuuid is mandatory — the UUID is erased on every boot.
          swapDevices = lib.mkForce [
            {
              device = "/dev/disk/by-partuuid/22f53553-15a6-42af-a045-1f79341e741e";
              randomEncryption.enable = true;
            }
          ];

          # No Wake-on-LAN here.  Two systemd.network.links used to set
          # WakeOnLan=magic on the dock NICs, but TLP re-applies
          # WOL_DISABLE="Y" on every power event and wins, so it never
          # actually worked.  To genuinely want WoL on this machine, set
          # WOL_DISABLE="N" in core/power.nix and restore the links.

          # ethtool/wakeonlan went with the WoL links above; esprimo declares
          # its own copies where they are actually used.

          # The eDP backlight is the largest single consumer on this machine:
          # ~3-4 W of an ~11 W idle draw at 100%.  Cap it to 40% whenever the
          # charger is pulled.  This only ever lowers brightness, so nudging it
          # back up on battery sticks until the next unplug, and plugging in
          # never overrides a level you chose by hand.
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
