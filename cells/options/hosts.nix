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
        selectedBranches =
          if unknownBranches != [ ] then
            throw ("Unknown branch names for ${hostName}: " + lib.concatStringsSep ", " unknownBranches)
          else
            map (name: cfg.branches.${name}) selectedBranchNames;
      in
      {
        inherit selectedBranchNames selectedBranches;
        nixosModules = lib.concatMap (branchCfg: branchCfg.nixosModules) selectedBranches;
        hmModules = lib.concatMap (branchCfg: branchCfg.hmModules) selectedBranches;
      };
  };
}
