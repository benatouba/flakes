{ inputs, ... }:
{
  config.my.branches.security.hmModules = [
    (
      { pkgs, ... }:
      let
        secretsRoot = toString inputs.nix-secrets;
        rbwPath =
          if builtins.pathExists "${secretsRoot}/rbw.nix" then
            "${secretsRoot}/rbw.nix"
          else
            ../../secrets/rbw.example.nix;
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
