_: {
  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          element-desktop
          # iamb (terminal client) is parked, not removed: uncomment here and
          # re-enable its overlay in overlays/default.nix to bring it back.
          # iamb
        ];
      }
    )
  ];
}
