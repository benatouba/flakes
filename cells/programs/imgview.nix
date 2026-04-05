_: {
  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      {
        home.packages = with pkgs; [ imv ];
      }
    )
  ];
}
