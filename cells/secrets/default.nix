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
  hmAgeKeyFile = "/home/${user}/.config/sops/age/keys.txt";

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
    (
      { pkgs, lib, ... }:
      {
        assertions = [ assertSecretsFile ];

        sops = {
          inherit defaultSopsFile;
          age.keyFile = hmAgeKeyFile;
        };

        home.activation.installUserSopsAgeKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          key_dir="$(dirname ${lib.escapeShellArg hmAgeKeyFile})"
          if ! [ -r ${lib.escapeShellArg hmAgeKeyFile} ]; then
            $DRY_RUN_CMD mkdir -p "$key_dir"
            $DRY_RUN_CMD chmod 700 "$key_dir"
            if /run/wrappers/bin/sg sops-keys -c 'test -r /persist/sops/age/keys.txt'; then
              $DRY_RUN_CMD /run/wrappers/bin/sg sops-keys -c '${pkgs.coreutils}/bin/install -m 600 /persist/sops/age/keys.txt ${lib.escapeShellArg hmAgeKeyFile}'
            else
              echo "Could not read /persist/sops/age/keys.txt to install ${hmAgeKeyFile}" >&2
              exit 1
            fi
          fi
        '';
      }
    )
  ];
}
