{ inputs, ... }:
{
  config.my.hmModules = [({ pkgs, ... }:
  let
    secrets = import "${inputs.nix-secrets}/rbw.nix";
  in {
    programs.rbw = {
      enable = true;
      settings = {
        inherit (secrets) email;
        inherit (secrets) base_url;
        pinentry = pkgs.pinentry-gnome3;
      };
    };
  })];
}
