{
  config,
  inputs,
  lib,
  ...
}:
let
  user = config.my.user.name;
  secretsRoot = toString inputs.nix-secrets;
  defaultSopsFile = "${secretsRoot}/secrets.yaml";
  rootPasswordKey = "password_hash_root";
  userPasswordKey = "password_hash_${user}";

  assertSecretsFile = {
    assertion = builtins.pathExists defaultSopsFile;
    message = "The secrets branch requires ${defaultSopsFile} to exist.";
  };

in
{

  config.my.branches.secrets.nixosModules = [
    inputs.sops-nix.nixosModules.sops
    (
      { config, ... }:
      {
        assertions = [ assertSecretsFile ];

        sops = {
          inherit defaultSopsFile;
          age.keyFile = "/persist/sops/age/keys.txt";
        };

        sops.secrets.${rootPasswordKey} = {
          neededForUsers = true;
          sopsFile = defaultSopsFile;
        };
        sops.secrets.${userPasswordKey} = {
          neededForUsers = true;
          sopsFile = defaultSopsFile;
        };

        users.mutableUsers = lib.mkForce false;
        users.users.root.hashedPasswordFile = lib.mkForce config.sops.secrets.${rootPasswordKey}.path;
        users.users.${user}.hashedPasswordFile = lib.mkForce config.sops.secrets.${userPasswordKey}.path;
      }
    )
  ];

  config.my.branches.secrets.hmModules = [
    inputs.sops-nix.homeManagerModules.sops
    {
      assertions = [ assertSecretsFile ];

      sops = {
        inherit defaultSopsFile;
        age.keyFile = "/persist/sops/age/keys.txt";
      };
    }
  ];
}
