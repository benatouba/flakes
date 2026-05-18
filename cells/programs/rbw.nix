{ inputs, ... }:
let
  secretsRoot = toString inputs.nix-secrets;
  rbwPath = "${secretsRoot}/rbw.nix";
in
{

  config.my.branches.personal.hmModules = [
    (
      { lib, pkgs, ... }:
      let
        hasRbwConfig = builtins.pathExists rbwPath;
        secrets = if hasRbwConfig then import rbwPath else { };
      in
      {
        assertions = [
          {
            assertion = hasRbwConfig;
            message = "The personal branch requires ${rbwPath} to exist.";
          }
        ];
      }
      // lib.optionalAttrs hasRbwConfig {
        programs.rbw = {
          enable = true;
          settings = {
            inherit (secrets) email;
            inherit (secrets) base_url;
            pinentry = pkgs.pinentry-gnome3;
          };
        };
      }
    )
  ];
}
