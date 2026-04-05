_: {
  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      {
        home.packages = [ pkgs.fastfetch ];
        xdg.configFile."fastfetch/config.jsonc".source = ../../dotfiles/fastfetch/config.jsonc;
      }
    )
  ];
}
