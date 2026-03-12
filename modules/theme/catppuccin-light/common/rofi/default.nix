{ lib, pkgs, user, ... }:
{
  home.file.".config/rofi/off.sh".source = lib.mkDefault ./off.sh;
  home.file.".config/rofi/launcher.sh".source = lib.mkDefault ./launcher.sh;
  home.file.".config/rofi/launcher_theme.rasi".source = lib.mkDefault ./launcher_theme.rasi;
  home.file.".config/rofi/powermenu.sh".source = lib.mkDefault ./powermenu.sh;
  home.file.".config/rofi/powermenu_theme.rasi".source = lib.mkDefault ./powermenu_theme.rasi;
}
