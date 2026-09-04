_: {
  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      {
        home.packages = with pkgs; [ matugen ];

        xdg.configFile."matugen" = {
          source = ../../dotfiles/matugen;
          recursive = true;
        };
      }
    )
  ];
}
