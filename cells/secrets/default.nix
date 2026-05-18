{ inputs, ... }:
let
  secretsRoot = toString inputs.nix-secrets;
  defaultSopsFile = "${secretsRoot}/secrets.yaml";
  assertSecretsFile = {
    assertion = builtins.pathExists defaultSopsFile;
    message = "The secrets branch requires ${defaultSopsFile} to exist.";
  };
in
{

  config.my.branches.secrets.nixosModules = [
    {
      assertions = [ assertSecretsFile ];

      sops = {
        inherit defaultSopsFile;
        age.keyFile = "/persist/sops/age/keys.txt";
      };
    }
  ];

  config.my.branches.secrets.hmModules = [
    {
      assertions = [ assertSecretsFile ];

      sops = {
        inherit defaultSopsFile;
        age.keyFile = "/persist/sops/age/keys.txt";
      };
    }
  ];
}
