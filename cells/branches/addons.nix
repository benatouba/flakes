{ config, lib, ... }:
let
  addonCfg = config.my.profile.addons;
in
{
  config.my.branches.addons = {
    description = "Operational and quality-of-life add-ons.";

    nixosModules = lib.flatten [
      (lib.optional addonCfg.ergonomics.enable (
        { pkgs, ... }:
        {
          environment.systemPackages = [ pkgs.nh ];
        }
      ))
      (lib.optional addonCfg.observability.enable (
        { pkgs, ... }:
        {
          environment.systemPackages = with pkgs; [
            nix-output-monitor
            nvd
          ];
        }
      ))
      (lib.optional addonCfg.deployment.enable (
        { pkgs, lib, ... }:
        {
          environment.systemPackages =
            (lib.optional (builtins.hasAttr "deploy-rs" pkgs) pkgs."deploy-rs")
            ++ (lib.optional (builtins.hasAttr "colmena" pkgs) pkgs.colmena);
        }
      ))
      (lib.optional addonCfg.attic.enable (
        { pkgs, lib, ... }:
        {
          environment.systemPackages =
            lib.optional (builtins.hasAttr "attic-client" pkgs)
              pkgs."attic-client";
        }
      ))
    ];

    hmModules = lib.flatten [
      (lib.optional addonCfg.ergonomics.enable (
        { ... }:
        {
          home.shellAliases = {
            ns = "nh os switch";
            nt = "nh os test";
            nc = "nh clean all --keep-since 7d --keep 5";
          };
        }
      ))
      (lib.optional addonCfg.observability.enable (
        { ... }:
        {
          home.shellAliases.ndiff = "nvd diff /run/current-system result";
        }
      ))
    ];
  };
}
