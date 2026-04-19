_: {
  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.element-desktop
          pkgs.iamb
        ];
      }
    )
  ];
}
