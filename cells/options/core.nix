{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.my = {
    user = {
      name = mkOption {
        type = types.str;
        default = "ben";
        description = "Unix username";
      };
      fullName = mkOption {
        type = types.str;
        default = "Benjamin Schmidt";
      };
      email = mkOption {
        type = types.str;
        default = "benschmidt@live.de";
      };
      githubUser = mkOption {
        type = types.str;
        default = "benatouba";
      };
    };

    stateVersion = mkOption {
      type = types.str;
      default = "25.05";
    };

    enableNoctalia = mkOption {
      type = types.bool;
      default = false;
    };

    nixosModules = mkOption {
      type = types.listOf types.deferredModule;
      default = [ ];
    };

    hmModules = mkOption {
      type = types.listOf types.deferredModule;
      default = [ ];
    };
  };
}
