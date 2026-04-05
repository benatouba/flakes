{ config, ... }:
let
  cfg = config.my;
in
{
  config.my.branches.legacy = {
    description = "Compatibility branch collecting legacy module accumulators.";
    nixosModules = cfg.nixosModules;
    hmModules = cfg.hmModules;
  };
}
