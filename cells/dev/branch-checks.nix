# Eval-time checks for the branch interface (needs validation, host seam).
{
  config,
  lib,
  myHostLib,
  ...
}:
let
  cfg = config.my;
  resolves =
    hostCfg:
    (builtins.tryEval (
      builtins.length
        (myHostLib.resolveBranches {
          inherit cfg hostCfg;
          hostName = "check";
        }).selectedBranches
    )).success;
  base = {
    includeProfileBranches = false;
  };
  cases = {
    # finance needs paperless, paperless needs secrets
    "missing-need-rejected" = !(resolves (base // { branches = [ "finance" ]; }));
    "satisfied-needs-accepted" = resolves (
      base
      // {
        branches = [
          "secrets"
          "paperless"
          "finance"
        ];
      }
    );
    # Selecting the ddns branch is what enables it.
    "ddns-selected-enables" = config.flake.nixosConfigurations.esprimo.config.my.ddns.enable;
    "dns-selected-enables" = config.flake.nixosConfigurations.rpi-pihole.config.my.dns.enable;
    "ddns-unselected-disabled" =
      !(config.flake.nixosConfigurations.thinkpad.config.my.ddns.enable or false);
  };
  # Host seam: hosts select branches; inline `nixosModules` are limited to
  # a grandfathered count per host. New hosts get 0.
  # TODO: shrink these as inline host modules move into branches.
  inlineModuleAllowlist = {
    thinkpad = 0;
    esprimo = 1;
    ec2 = 1;
    rpi-pihole = 1;
  };
  seamViolations = lib.mapAttrsToList (
    name: hostCfg:
    let
      allowed = inlineModuleAllowlist.${name} or 0;
    in
    lib.optionalString (builtins.length hostCfg.nixosModules > allowed)
      "${name} has ${toString (builtins.length hostCfg.nixosModules)} inline nixosModules (allowed ${toString allowed})"
  ) cfg.hosts;
  failed =
    (lib.filter (v: v != "") seamViolations) ++ lib.attrNames (lib.filterAttrs (_: ok: !ok) cases);
in
{
  config.perSystem =
    { pkgs, ... }:
    {
      checks.branch-needs = pkgs.runCommand "branch-needs-check" { } (
        if failed == [ ] then "touch $out" else "echo 'failed: ${lib.concatStringsSep ", " failed}'; exit 1"
      );
    };
}
