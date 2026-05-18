{
  config,
  inputs,
  lib,
  myHostLib,
  ...
}:
let
  cfg = config.my;
  hostCfg = cfg.hosts.thinkpad;
  user = cfg.user.name;
  branches = myHostLib.resolveBranches {
    inherit cfg hostCfg;
    hostName = "thinkpad";
  };
in
{
  config.my.hosts.thinkpad = {
    system = "x86_64-linux";
    branches = [ ];
    hardwareModules = [
      inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p14s-amd-gen2
    ];
  };

  config.flake.nixosConfigurations.thinkpad = lib.nixosSystem {
    system = hostCfg.system;
    modules = [
      ./_hardware.nix
      inputs.impermanence.nixosModules.impermanence
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
      {
        networking.hostName = "thinkpad";

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs; };
          users.${user}.imports =
            branches.hmModules
            ++ hostCfg.hmModules
            ++ [
              inputs.sops-nix.homeManagerModules.sops
              inputs.hyprland.homeManagerModules.default
              (
                { lib, ... }:
                {
                  home = {
                    username = user;
                    homeDirectory = lib.mkForce "/home/${user}";
                    stateVersion = cfg.stateVersion;
                  };
                  programs.home-manager.enable = true;
                }
              )
            ];
        };
      }
    ]
    ++ branches.nixosModules
    ++ hostCfg.nixosModules
    ++ hostCfg.hardwareModules;
  };
}
