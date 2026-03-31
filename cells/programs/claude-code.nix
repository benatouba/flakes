{ inputs, ... }:
{
  config.my.hmModules = [
    (
      { pkgs, ... }:
      {
        home.packages = [ inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default ];
      }
    )
  ];
}
