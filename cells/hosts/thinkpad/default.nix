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
    branches = [ "desktop" ];
    nixosModules = [
      (
        { pkgs, ... }:
        {
          programs.steam = {
            enable = true;
            protontricks.enable = true;
            extraCompatPackages = [ pkgs.proton-ge-bin ];
          };
        }
      )
    ];
    hardwareModules = [
      inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p14s-amd-gen2
    ];
  };

  config.flake.nixosConfigurations.thinkpad = lib.nixosSystem {
    system = hostCfg.system;
    modules = [
      ./_hardware.nix
      {
        config.nixpkgs.config.permittedInsecurePackages = [
          "electron-39.8.10"
        ];
      }
      inputs.impermanence.nixosModules.impermanence
      inputs.home-manager.nixosModules.home-manager
      (
        { pkgs, ... }:
        {
          networking = {
            hostName = "thinkpad";
          };

          systemd.network.links = {
            "40-enp2s0f0-wol" = {
              matchConfig.OriginalName = "enp2s0f0";
              linkConfig.WakeOnLan = "magic";
            };
            "40-enp5s0-wol" = {
              matchConfig.OriginalName = "enp5s0";
              linkConfig.WakeOnLan = "magic";
            };
            "40-wlp3s0-wol" = {
              matchConfig.OriginalName = "wlp3s0";
              linkConfig.WakeOnLan = "magic";
            };
          };

          environment.systemPackages = with pkgs; [
            ethtool
            wakeonlan
          ];

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs; };
            users.${user}.imports =
              branches.hmModules
              ++ hostCfg.hmModules
              ++ [
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
      )
    ]
    ++ branches.nixosModules
    ++ hostCfg.nixosModules
    ++ hostCfg.hardwareModules;
  };
}
