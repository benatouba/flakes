_: {
  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      {
        home.packages = [ pkgs.opencode ];
      }
    )
  ];
}
