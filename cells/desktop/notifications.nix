{ ... }:
{
  config.my.hmModules = [({ pkgs, ... }: {
    home.packages = with pkgs; [ swaynotificationcenter ];

    xdg.configFile."swaync" = {
      source = ../../dotfiles/swaync;
      recursive = true;
    };
  })];
}
