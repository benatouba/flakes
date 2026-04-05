{ inputs, ... }:
let
  secretsRoot = toString inputs.nix-secrets;
  fallbackSopsFile = ../../secrets/secrets.example.yaml;
  defaultSopsFile =
    if builtins.pathExists "${secretsRoot}/secrets.yaml" then
      "${secretsRoot}/secrets.yaml"
    else
      fallbackSopsFile;
in
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
