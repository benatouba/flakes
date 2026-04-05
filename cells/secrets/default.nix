{ inputs, ... }:
let
  secretsRoot = toString inputs.nix-secrets;
  defaultSopsFile = "${secretsRoot}/secrets.yaml";
in
assert builtins.pathExists defaultSopsFile;
{

  config.my.branches.security.nixosModules = [
    {
      sops = {
        inherit defaultSopsFile;
        age.keyFile = "/persist/sops/age/keys.txt";
      };
    }
  ];

  config.my.branches.security.hmModules = [
    {
      sops = {
        inherit defaultSopsFile;
        age.keyFile = "/persist/sops/age/keys.txt";
      };
    }
  ];
}
