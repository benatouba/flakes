# Eval-time checks for the branch interface: needs validation, branch enable
# wiring, and the host seam. Each is its own check so failures are legible.
{
  config,
  lib,
  myHostLib,
  ...
}:
let
  cfg = config.my;
  nixosOf = host: config.flake.nixosConfigurations.${host}.config;

  # --- needs validation -----------------------------------------------------
  resolve =
    hostCfg:
    myHostLib.resolveBranches {
      inherit cfg hostCfg;
      hostName = "check-host";
    };
  isolated = {
    includeProfileBranches = false;
  };
  # Cases assert on the resolver's plain-data problems, so a failure for an
  # unrelated reason cannot masquerade as the expected one. The throw text
  # is built from the same data (see resolveBranches).
  missing = branches: (resolve (isolated // { inherit branches; })).missingNeeds;
  needsCases = {
    "missing-need-reported" =
      missing [ "finance" ] == [
        {
          branch = "finance";
          need = "paperless";
        }
      ];
    "unknown-branch-reported" =
      (resolve (isolated // { branches = [ "no-such-branch" ]; })).unknownBranches
      == [ "no-such-branch" ];
    "satisfied-needs-accepted" =
      missing [
        "secrets"
        "paperless"
        "finance"
      ] == [ ];
    "needs-not-transitive" =
      map (m: m.need) (missing [
        "finance"
        "paperless"
      ]) == [ "secrets" ];
    "no-needs-name-unknown-branches" = lib.all (
      b: (resolve (isolated // { branches = [ b ]; })).unknownNeeds == [ ]
    ) (lib.attrNames cfg.branches);
  };

  # --- branch enable wiring (selecting a branch enables it) --------------------
  enableCases = {
    "ddns-selected-enables" = (nixosOf "esprimo").my.ddns.enable;
    "dns-selected-enables" = (nixosOf "esprimo").my.dns.enable;
    "dns-local-records-via-host-module" =
      (nixosOf "esprimo").my.dns.localRecords ? "workout.benrlschmidt.de";
    "ddns-unselected-has-no-option" = !(((nixosOf "thinkpad") ? my) && (nixosOf "thinkpad").my ? ddns);
  };

  # --- host seam ---------------------------------------------------------------
  # Hosts select branches. Inline modules on a host are bypasses of the
  # seam; each one is listed here by what it is, so swapping one bypass for
  # another changes the list and fails review. New hosts get none.
  # TODO: shrink each entry by moving its content into a branch.
  grandfathered = {
    nixosModules = {
      esprimo = [ "hostname, nameservers, WoL link, finance wiring (move to branches)" ];
      ec2 = [ "amazon-image import, root/user keys, cloud-init (move to an ec2 branch)" ];
      rpi-pihole = [ "hostname, fileSystems, authorized keys (retired host; do not extend)" ];
    };
    hmModules = {
      thinkpad = [
        "inline home-manager module in the thinkpad host (move to a desktop/personal branch)"
      ];
    };
  };
  unknownAllowlistHosts = lib.filter (h: !(cfg.hosts ? ${h})) (
    lib.unique (lib.concatMap lib.attrNames (lib.attrValues grandfathered))
  );
  countViolations =
    kind:
    lib.concatLists (
      lib.mapAttrsToList (
        name: hostCfg:
        let
          allowed = grandfathered.${kind}.${name} or [ ];
        in
        lib.optional (builtins.length hostCfg.${kind} != builtins.length allowed)
          "${name}: ${
            toString (builtins.length hostCfg.${kind})
          } inline ${kind}, allowlist lists ${toString (builtins.length allowed)}"
      ) cfg.hosts
    );
  # Direct feature imports: host files must not reach into other cells by
  # relative path (`../...`). Host-local files (`./_hardware.nix`) are fine.
  hostDirs = lib.attrNames (lib.filterAttrs (_: t: t == "directory") (builtins.readDir ../hosts));
  directImports = lib.concatMap (
    h:
    let
      src = builtins.readFile (../hosts + "/${h}/default.nix");
    in
    lib.optional (builtins.match ".*[ \\[(]\\.\\./[A-Za-z_].*" src != null) "${h}: imports by ../ path"
  ) hostDirs;
  seamViolations =
    map (h: "allowlist names unknown host ${h}") unknownAllowlistHosts
    ++ countViolations "nixosModules"
    ++ countViolations "hmModules"
    ++ directImports;

  mkCheck =
    pkgs: name: failed:
    pkgs.runCommand name { } (
      if failed == [ ] then
        "touch $out"
      else
        "echo ${lib.escapeShellArg "failed: ${lib.concatStringsSep ", " failed}"}; exit 1"
    );
  failing = cases: lib.attrNames (lib.filterAttrs (_: ok: !ok) cases);
in
{
  config.perSystem =
    { pkgs, ... }:
    {
      checks = {
        branch-needs = mkCheck pkgs "branch-needs-check" (failing needsCases);
        branch-enable = mkCheck pkgs "branch-enable-check" (failing enableCases);
        host-seam = mkCheck pkgs "host-seam-check" seamViolations;
      };
    };
}
