_: {
  config.my.branches.desktop.hmModules = [
    {
      xdg.configFile."bat" = {
        source = ../../dotfiles/bat;
        recursive = true;
      };
    }
  ];
}
