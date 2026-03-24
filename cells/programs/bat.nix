{ ... }:
{
  config.my.hmModules = [{
    xdg.configFile."bat" = {
      source = ../../dotfiles/bat;
      recursive = true;
    };
  }];
}
