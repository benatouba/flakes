{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.my.hosts = mkOption {
    type = types.attrsOf (
      types.submodule {
        options = {
          system = mkOption {
            type = types.str;
            default = "x86_64-linux";
          };
          branches = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Host-specific branches added after profile branches.";
          };
          includeProfileBranches = mkOption {
            type = types.bool;
            default = true;
            description = "Whether this host includes my.profile.branches before its host-specific branches.";
          };
          nixosModules = mkOption {
            type = types.listOf types.deferredModule;
            default = [ ];
          };
          hmModules = mkOption {
            type = types.listOf types.deferredModule;
            default = [ ];
          };
          hardwareModules = mkOption {
            type = types.listOf types.deferredModule;
            default = [ ];
          };
        };
      }
    );
    default = { };
  };

  config._module.args.myHostLib = {
    # `my.<branch>.enable` for NixOS-level branch modules: selecting the branch
    # enables it, hosts may still `mkForce false`.
    mkDefaultOnEnable = { lib, description }: lib.mkEnableOption description // { default = true; };

    resolveBranches =
      {
        cfg,
        hostName,
        hostCfg,
      }:
      let
        selectedBranchNames = lib.unique (
          (lib.optionals hostCfg.includeProfileBranches cfg.profile.branches) ++ hostCfg.branches
        );
        knownBranchNames = builtins.attrNames cfg.branches;
        unknownBranches = builtins.filter (
          name: !(builtins.elem name knownBranchNames)
        ) selectedBranchNames;
        # Only known branches are inspected, so this does not depend on the
        # unknown-name throw below. `needs` is deliberately not transitive:
        # every need must itself be selected (and declare its own needs).
        missingNeeds = lib.concatMap (
          name:
          map (need: {
            branch = name;
            inherit need;
          }) (builtins.filter (need: !(builtins.elem need selectedBranchNames)) cfg.branches.${name}.needs)
        ) (builtins.filter (name: builtins.elem name knownBranchNames) selectedBranchNames);
        # A need naming a nonexistent branch is a declaration bug, not a host bug.
        unknownNeeds = lib.concatMap (
          name:
          map (need: "${name} -> ${need}") (
            builtins.filter (need: !(builtins.elem need knownBranchNames)) cfg.branches.${name}.needs
          )
        ) (builtins.filter (name: builtins.elem name knownBranchNames) selectedBranchNames);
        selectedBranches =
          if unknownBranches != [ ] then
            throw ("Unknown branch names for ${hostName}: " + lib.concatStringsSep ", " unknownBranches)
          else if unknownNeeds != [ ] then
            throw ("Branch needs name unknown branches: " + lib.concatStringsSep ", " unknownNeeds)
          else if missingNeeds != [ ] then
            throw (
              lib.concatMapStringsSep "\n" (
                m:
                "Host ${hostName} selects branch '${m.branch}' which needs branch '${m.need}', but it is not selected."
              ) missingNeeds
            )
          else
            map (name: cfg.branches.${name}) selectedBranchNames;
      in
      {
        # Plain data so checks can assert on problems without parsing throws.
        inherit
          selectedBranchNames
          selectedBranches
          missingNeeds
          unknownBranches
          unknownNeeds
          ;
        nixosModules = lib.concatMap (branchCfg: branchCfg.nixosModules) selectedBranches;
        hmModules = lib.concatMap (branchCfg: branchCfg.hmModules) selectedBranches;
      };
  };
}
