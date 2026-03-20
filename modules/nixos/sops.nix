{ inputs, ... }:

{
  sops = {
    defaultSopsFile = "${inputs.nix-secrets}/secrets.yaml";
    age.keyFile = "/persist/sops/age/keys.txt";
  };
}
