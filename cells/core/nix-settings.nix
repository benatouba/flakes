{
  config,
  inputs,
  lib,
  ...
}:
let
  isHardened = config.my.profile.security.level == "hardened";
in
{
  config.my.branches.base.nixosModules = [
    (
      { pkgs, ... }:
      {
        nix = {
          settings = {
            auto-optimise-store = true;
            sandbox = true;
            allowed-users = [ "@wheel" ];
            trusted-users = [
              "root"
              "@wheel"
            ];
            max-jobs = "auto";
            cores = 0;
            builders-use-substitutes = true;
            accept-flake-config = false;
            experimental-features = [
              "nix-command"
              "flakes"
            ];
            substituters = [
              "https://cache.nixos.org"
              "https://nix-community.cachix.org"
              "https://hyprland.cachix.org"
              "https://devenv.cachix.org"
              "https://noctalia.cachix.org"
            ];
            trusted-public-keys = [
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
              "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
              "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
            ];
          }
          // lib.optionalAttrs isHardened {
            min-free = 2147483648;
            max-free = 10737418240;
          };
          gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 14d";
          };
          package = pkgs.nixVersions.latest;
          registry.nixpkgs.flake = inputs.nixpkgs;
          extraOptions = ''
            keep-outputs     = true
            keep-derivations = true
          '';
        };
        nixpkgs.config.allowUnfree = true;

        system = {
          autoUpgrade = {
            enable = false;
            channel = "https://nixos.org/channels/nixos-unstable";
          };
          stateVersion = config.my.stateVersion;
        };
      }
    )
  ];
}
