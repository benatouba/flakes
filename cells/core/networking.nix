{ ... }:
{
  config.my.nixosModules = [({ ... }: {
    services = {
      dbus.enable = true;
    };
  })];
}
