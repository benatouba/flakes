{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    xsettingsd
    kdePackages.qt6ct
  ];

  xdg.configFile."xsettingsd/xsettingsd.conf".source = ../../../../dotfiles/xsettingsd/xsettingsd.conf;
  xdg.configFile."qt6ct/qt6ct.conf".source = ../../../../dotfiles/qt6ct/qt6ct.conf;
  xdg.configFile."electron-flags.conf".source = ../../../../dotfiles/electron-flags.conf;
  xdg.configFile."electron12-flags.conf".source = ../../../../dotfiles/electron-flags.conf;
  xdg.configFile."chromium-flags.conf".source = ../../../../dotfiles/chromium-flags.conf;
}
