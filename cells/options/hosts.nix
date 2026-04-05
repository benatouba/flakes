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
}
