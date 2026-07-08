_: {
  config.my.branches.base.nixosModules = [
    (
      { pkgs, ... }:
      {
        boot = {
          supportedFilesystems = [ "btrfs" ];
          # Pinned to the latest 6.x series; linuxPackages_latest would jump to major version 7.
          kernelPackages = pkgs.linuxPackages_6_12;
          loader = {
            grub = {
              enable = true;
              efiSupport = true;
              efiInstallAsRemovable = true;
              useOSProber = false;
              configurationLimit = 5;
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

        services.journald.extraConfig = ''
          SystemMaxUse=200M
          RuntimeMaxUse=200M
        '';
      }
    )
  ];
}
