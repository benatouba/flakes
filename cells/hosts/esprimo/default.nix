{
  config,
  lib,
  myHostLib,
  ...
}:
let
  cfg = config.my;
  hostCfg = cfg.hosts.esprimo;
  branches = myHostLib.resolveBranches {
    inherit cfg hostCfg;
    hostName = "esprimo";
  };

  sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHwt/9sYFxYhYB8kAeaOraASje7EqQusTCJtvvNVt+hx benschmidt@live.de";
in
{
  config.my.hosts.esprimo = {
    system = "x86_64-linux";
    includeProfileBranches = false;
    branches = [
      "secrets"
      "server"
      "dns"
      "vpn"
    ];

    nixosModules = [
      (
        { pkgs, ... }:
        {
          networking = {
            hostName = "esprimo";
            nameservers = [
              "127.0.0.1"
              "::1"
              "1.1.1.1"
              "8.8.8.8"
            ];
          };

          systemd.network.links."40-enp1s0-wol" = {
            matchConfig.OriginalName = "enp1s0";
            linkConfig.WakeOnLan = "magic";
          };

          environment.systemPackages = with pkgs; [
            ethtool
            wakeonlan
          ];

          boot.loader = {
            systemd-boot.enable = true;
            efi.canTouchEfiVariables = true;
          };

          fileSystems = {
            "/" = lib.mkDefault {
              device = "/dev/disk/by-label/nixos";
              fsType = "ext4";
            };
            "/boot" = lib.mkDefault {
              device = "/dev/sda1";
              fsType = "vfat";
              options = [ "umask=0077" ];
            };
          };

          hardware.cpu.intel.updateMicrocode = lib.mkDefault true;

          users.users.${cfg.user.name}.openssh.authorizedKeys.keys = [ sshKey ];

          services.openssh.settings.PermitRootLogin = lib.mkForce "no";

          security.sudo.extraConfig = ''
            ${cfg.user.name} ALL=(root) NOPASSWD: /bin/sh -c exec\ env\ -i\ PATH=*\ *\ sh\ nix-env\ -p\ /nix/var/nix/profiles/system\ --set\ /nix/store/*-nixos-system-esprimo-*
            ${cfg.user.name} ALL=(root) NOPASSWD: /bin/sh -c *\ /nix/store/*-nixos-system-esprimo-*/bin/switch-to-configuration\ *
          '';

        }
      )
    ];
  };

  config.flake.nixosConfigurations.esprimo = lib.nixosSystem {
    system = hostCfg.system;
    modules = [
      ./_hardware.nix
    ]
    ++ branches.nixosModules
    ++ hostCfg.nixosModules
    ++ hostCfg.hardwareModules;
  };
}
