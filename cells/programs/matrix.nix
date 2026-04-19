_: {
  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          element-desktop
          iamb
        ];
      }
    )
  ];
}
