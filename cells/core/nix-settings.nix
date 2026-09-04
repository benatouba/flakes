{
  config,
  inputs,
  lib,
  ...
}:
let
  isHardened = config.my.profile.security.level == "hardened";
  user = config.my.user.name;
in
{
  config.my.branches.base.nixosModules = [
    (
      { pkgs, ... }:
      {
        nix = {
          settings = {
            # Deliberately off — see nix.optimise below.  auto-optimise-store
            # runs a full hard-link dedup pass at the end of every single
            # build, which is a lot of extra disk churn on a laptop.
            auto-optimise-store = false;
            sandbox = true;
            allowed-users = [ "@wheel" ];
            trusted-users = lib.mkForce [
              "root"
              user
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
            ];
            trusted-public-keys = [
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
              "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
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
            randomizedDelaySec = "30min";
          };

          # Same dedup work as auto-optimise-store, but batched into one
          # weekly run just after GC instead of after every build.
          optimise = {
            automatic = true;
            dates = [ "weekly" ];
            randomizedDelaySec = "45min";
          };
          package = pkgs.nixVersions.latest;
          registry.nixpkgs.flake = inputs.nixpkgs;
          extraOptions = ''
            netrc-file = /run/secrets/github_netrc
            keep-outputs     = true
            keep-derivations = true
            warn-dirty       = true
          '';
        };
        nixpkgs.config.allowUnfree = true;

        # Store maintenance is heavily I/O bound and can run for minutes.
        # Never let it fire on battery; a run skipped this way is simply
        # dropped until the timer's next weekly elapse, which is fine for GC.
        # Run `systemctl start nix-gc nix-optimise` by hand to force one.
        systemd.services = {
          nix-gc.unitConfig.ConditionACPower = true;
          nix-optimise.unitConfig.ConditionACPower = true;
        };

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
