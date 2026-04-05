{ inputs, ... }:
let
  secretsRoot = toString inputs.nix-secrets;
  rbwPath = "${secretsRoot}/rbw.nix";
in
assert builtins.pathExists rbwPath;
{

  config.my.branches.security.hmModules = [
    (
      { pkgs, ... }:
      let
        secrets = import rbwPath;
      in
      {
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
