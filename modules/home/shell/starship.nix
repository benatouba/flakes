{ theme, ... }:

let
  starshipConfig = builtins.replaceStrings
    [ "@starshipPalette@" ]
    [ theme.starshipPalette ]
    (builtins.readFile ../../../dotfiles/starship.toml);
in
{
  # Starship config (palette selected at build time based on theme)
  xdg.configFile."starship.toml".text = starshipConfig;
}
