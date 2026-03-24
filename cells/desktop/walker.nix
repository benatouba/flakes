{ ... }:
{
  config.my.hmModules = [({ pkgs, ... }: {
    home.packages = with pkgs; [ walker ];

    xdg.configFile."walker" = {
      source = ../../dotfiles/walker;
      recursive = true;
    };
  })];
}
