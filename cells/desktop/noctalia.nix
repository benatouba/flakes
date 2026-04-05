{ config, lib, ... }:
{
  config.my.branches.desktop.hmModules = lib.optionals config.my.enableNoctalia [
    (
      { pkgs, ... }:
      {
        home.packages = [ pkgs.noctalia-shell ];
      }
    )
  ];
}
