{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.my;
  hostCfg = cfg.hosts.thinkpad;
  user = cfg.user.name;
in
{
  config.my.hosts.thinkpad = {
    system = "x86_64-linux";
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
            cfg.hmModules
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
    ++ cfg.nixosModules
    ++ hostCfg.nixosModules
    ++ hostCfg.hardwareModules;
  };
}
