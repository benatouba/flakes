{ config, ... }:
let
  user = config.my.user.name;
in
{
  config.my.hmModules = [({ config, ... }: {
    home.file."projects/status-alganize".source =
      config.lib.file.mkOutOfStoreSymlink
        "/mnt/@home/${user}/projects/alganize-soilmonitor";
  })];
}
