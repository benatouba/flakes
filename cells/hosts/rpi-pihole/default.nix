{
  config,
  inputs,
  lib,
  myHostLib,
  ...
}:
let
  cfg = config.my;
  hostCfg = cfg.hosts.rpi-pihole;
  branches = myHostLib.resolveBranches {
    inherit cfg hostCfg;
    hostName = "rpi-pihole";
  };
in
{
  config.my.hosts.rpi-pihole = {
    system = "armv7l-linux";
    includeProfileBranches = false;
    branches = [
      "server"
      "dns"
    ];
    hardwareModules = [ inputs.nixos-hardware.nixosModules.raspberry-pi-2 ];
    nixosModules = [
      (
        { ... }:
        {
          networking = {
            hostName = "rpi-pihole";
          };

          fileSystems = {
            "/" = lib.mkDefault {
              device = "/dev/mmcblk0p2";
              fsType = "ext4";
            };
            "/boot" = lib.mkDefault {
              device = "/dev/mmcblk0p1";
              fsType = "vfat";
              options = [
                "fmask=0022"
                "dmask=0022"
              ];
            };
          };

          users.users.${cfg.user.name}.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHwt/9sYFxYhYB8kAeaOraASje7EqQusTCJtvvNVt+hx benschmidt@live.de"
          ];
        }
      )
    ];
  };

  config.flake.nixosConfigurations.rpi-pihole = lib.nixosSystem {
    system = hostCfg.system;
    modules = branches.nixosModules ++ hostCfg.nixosModules ++ hostCfg.hardwareModules;
  };
}
