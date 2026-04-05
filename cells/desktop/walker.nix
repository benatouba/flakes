_: {
  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      {
        home.packages = with pkgs; [ walker ];

        xdg.configFile."walker" = {
          source = ../../dotfiles/walker;
          recursive = true;
        };
      }
    )
  ];
}
