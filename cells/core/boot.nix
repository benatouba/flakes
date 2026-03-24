{ ... }:
{
  config.my.nixosModules = [({ pkgs, ... }: {
    boot = {
      supportedFilesystems = [ "btrfs" ];
      kernelPackages = pkgs.linuxPackages_latest;
      loader = {
        grub = {
          enable = true;
          efiSupport = true;
          efiInstallAsRemovable = true;
          useOSProber = false;
          configurationLimit = 10;
          mirroredBoots = [
            {
              path = "/boot/efi";
              efiSysMountPoint = "/boot/efi";
              devices = [ "nodev" ];
            }
          ];
        };
        efi = {
          canTouchEfiVariables = false;
          efiSysMountPoint = "/boot/efi";
        };
        timeout = 3;
      };
      kernelParams = [
        "quiet"
        "splash"
      ];
      consoleLogLevel = 0;
      initrd.verbose = false;
    };
  })];
}
