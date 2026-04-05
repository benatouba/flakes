{ inputs, ... }:
{
  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      {
        home.packages = [ inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default ];
      }
    )
  ];
}
