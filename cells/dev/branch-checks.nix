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

  failing = cases: lib.attrNames (lib.filterAttrs (_: ok: !ok) cases);

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
  # Hosts select branches. Inline modules on a host are bypasses of the seam.
  # Inline modules have no identity Nix can compare, so the grandfathered
  # bypasses are pinned by count per host; the comment says which they are.
  # A new host gets none. A swapped bypass is caught in review, not here.
  # TODO: shrink each entry by moving its content into a branch.
  grandfathered = {
    nixosModules = {
      esprimo = 1; # hostname, nameservers, WoL link, dns localRecords, finance wiring
      ec2 = 1; # amazon-image import, keys, cloud-init (move to an ec2 branch)
      rpi-pihole = 1; # hostname, fileSystems, keys (do not extend)
    };
    hmModules = {
      thinkpad = 1; # inline home-manager module (move to a desktop/personal branch)
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
          allowed = grandfathered.${kind}.${name} or 0;
          actual = builtins.length hostCfg.${kind};
        in
        lib.optional (
          actual != allowed
        ) "${name}: ${toString actual} inline ${kind}, allowed ${toString allowed}"
      ) cfg.hosts
    );
  # Direct feature imports: host files must not reach into other cells by
  # relative path (`../...`). Scanned line by line, ignoring comment lines,
  # because `.` in builtins.match does not cross newlines.
  importsParent =
    src:
    lib.any (
      line:
      !(lib.hasPrefix "#" (lib.trim line)) && builtins.match ".*[ \\[(]\\.\\./[A-Za-z_.].*" line != null
    ) (lib.splitString "\n" src);
  scannerCases = {
    "scanner-flags-list-import" = importsParent "{\n  imports = [ ../../server/x.nix ];\n}";
    "scanner-flags-multiline-import" = importsParent "{\n  imports = [\n    ../server/x.nix\n  ];\n}";
    "scanner-ignores-comments" = !(importsParent "# see ../server/x.nix\n{ }");
    "scanner-allows-local-files" = !(importsParent "{ imports = [ ./hw.nix ]; }");
  };
  hostDirs = lib.attrNames (lib.filterAttrs (_: t: t == "directory") (builtins.readDir ../hosts));
  directImports = lib.concatMap (
    h:
    lib.optional (importsParent (
      builtins.readFile (../hosts + "/${h}/default.nix")
    )) "${h}: imports by ../ path"
  ) hostDirs;
  seamViolations =
    map (h: "allowlist names unknown host ${h}") unknownAllowlistHosts
    ++ countViolations "nixosModules"
    ++ countViolations "hmModules"
    ++ failing scannerCases
    ++ directImports;

  mkCheck =
    pkgs: name: failed:
    pkgs.runCommand name { } (
      if failed == [ ] then
        "touch $out"
      else
        "echo ${lib.escapeShellArg "failed: ${lib.concatStringsSep ", " failed}"}; exit 1"
    );
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
