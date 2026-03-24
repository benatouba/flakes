{ ... }:
{
  config.my.hmModules = [({ pkgs, ... }: {
    home.packages = with pkgs; [ rofi ];
    xdg.configFile."rofi".source = ../../dotfiles/rofi;
  })];
}
