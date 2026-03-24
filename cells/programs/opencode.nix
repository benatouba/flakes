{ ... }:
{
  config.my.hmModules = [({ pkgs, ... }: {
    home.packages = [ pkgs.opencode ];
  })];
}
