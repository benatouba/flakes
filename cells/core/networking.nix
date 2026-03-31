{ ... }:
{
  config.my.nixosModules = [
    (
      { pkgs, ... }:
      {
        services = {
          dbus.enable = true;
        };

        networking.networkmanager.plugins = [ pkgs.networkmanager-openconnect ];

        environment.systemPackages = [ pkgs.openconnect ];
      }
    )
  ];
}
