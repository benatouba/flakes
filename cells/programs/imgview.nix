{ ... }:
{
  config.my.hmModules = [({ pkgs, ... }: {
    home.packages = with pkgs; [ imv ];
  })];
}
