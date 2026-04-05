{ config, ... }:
let
  theme = config.my.theme;
  starshipConfig = builtins.replaceStrings [ "@starshipPalette@" ] [ theme.starshipPalette ] (
    builtins.readFile ../../dotfiles/starship.toml
  );
in
{
  config.my.branches.base.hmModules = [
    {
      xdg.configFile."starship.toml".text = starshipConfig;
    }
  ];
}
