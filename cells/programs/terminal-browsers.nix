_: {
  # Terminal alternatives belong to the shell trunk, not a host leaf or GUI branch.
  config.my.branches.base.hmModules = [
    (
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.lynx
          pkgs.elinks
        ];
      }
    )
  ];
}
