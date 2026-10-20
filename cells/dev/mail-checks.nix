{ ... }:
{
  config.perSystem =
    { pkgs, ... }:
    {
      checks.mail-tools =
        pkgs.runCommand "mail-tools-check"
          {
            nativeBuildInputs = [
              pkgs.mail-tools.check
            ];
          }
          ''
            check-mail-tools
            touch "$out"
          '';
    };
}
