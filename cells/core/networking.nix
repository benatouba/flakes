{ ... }:
{
  config.my.nixosModules = [({ ... }: {
    services = {
      openssh.enable = true;
      dbus.enable = true;
    };
  })];
}
