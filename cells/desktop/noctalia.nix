{ config, lib, ... }:
{
  config.my.hmModules = lib.optionals config.my.enableNoctalia [
    ({ pkgs, ... }: {
      home.packages = [ pkgs.noctalia-shell ];
    })
  ];
}
