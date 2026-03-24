{ inputs, ... }:
{
  config.my.nixosModules = [{
    sops = {
      defaultSopsFile = "${inputs.nix-secrets}/secrets.yaml";
      age.keyFile = "/persist/sops/age/keys.txt";
    };
  }];

  config.my.hmModules = [{
    sops = {
      defaultSopsFile = "${inputs.nix-secrets}/secrets.yaml";
      age.keyFile = "/persist/sops/age/keys.txt";
    };
  }];
}
