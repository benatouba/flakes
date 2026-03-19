{ pkgs, inputs, ... }:

let
  secrets = import "${inputs.nix-secrets}/rbw.nix";
in
{
  programs.rbw = {
    enable = true;
    settings = {
      email = secrets.email;
      base_url = secrets.base_url;
      pinentry = pkgs.pinentry-gnome3;
    };
  };
}
