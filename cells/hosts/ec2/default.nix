{
  config,
  inputs,
  lib,
  myHostLib,
  ...
}:
let
  cfg = config.my;
  hostCfg = cfg.hosts.ec2;
  branches = myHostLib.resolveBranches {
    inherit cfg hostCfg;
    hostName = "ec2";
  };
  ec2Modules = branches.nixosModules ++ hostCfg.nixosModules ++ hostCfg.hardwareModules;
in
{
  config.my.hosts.ec2 = {
    system = "x86_64-linux";
    includeProfileBranches = false;
    branches = [
      "server"
      "matrix"
    ];
    nixosModules = [
      (
        { modulesPath, ... }:
        {
          imports = [
            (modulesPath + "/virtualisation/amazon-image.nix")
          ];

          networking.hostName = "ec2";

          users.users.root.hashedPasswordFile = lib.mkForce null;
          users.users.${cfg.user.name} = {
            hashedPasswordFile = lib.mkForce null;
            openssh.authorizedKeys.keys = [
              "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCfKmjdaT7QboU53djdNCJx5b8Ps6kpvW/cIXN5nZEa2MvUPNEibk4SOYSkFU7wf6udVQec0IZuYFhLNgPNZLzavoM/Fj/0/Y2Oid35KufrsgPlaIh8t7/cAY/Vwemw0tesiIHeECkptJdqNIi52Qw5A/TlPVscXGbit3GT3K7cjWMTAGaQpJLFi2xyTnS1c5ZvHINaC5hTGVNcfWziNbcxhKqI8Z8NSDhQonvo7F0wjzGt0N9qvbGLtyJ288IipG6PMnYyu7xX72o7XWPyD5t7ty06GY+RFe0d0b2bmqU/YmMdbJurSDeCrouA80+ZcqgZbKJolDQlY3V2ARKxWa1T"
            ];
          };
          users.mutableUsers = true;

          services.cloud-init.enable = true;
        }
      )
    ];
  };

  config.my.matrix = {
    enable = true;
    domain = "matrix.benrlschmidt.de";
    enableTelegramBridge = false;
    enableWhatsappBridge = false;
    enableSignalBridge = false;
  };

  config.flake.nixosConfigurations.ec2 = lib.nixosSystem {
    system = hostCfg.system;
    modules = ec2Modules;
  };

  config.flake.packages.${hostCfg.system}.ec2-amazon = inputs.nixos-generators.nixosGenerate {
    system = hostCfg.system;
    format = "amazon";
    modules = ec2Modules ++ [
      # The `amazon` format pulls in maintainers/scripts/ec2/amazon-image.nix,
      # which pins virtualisation.diskSize to a fixed 4G with `mkOverride 1490`.
      # Once the closure outgrows that, grub-install fails with "No space left
      # on device" inside the image and the builder VM panics on it -- which
      # surfaces only as "Virtual machine didn't produce an exit code".
      #
      # `nixosConfigurations.ec2` already resolves this option to "auto"; this
      # just keeps the image build in step with it, so the size follows the
      # closure instead of needing a bigger magic number each time it grows.
      # Sizing tightly is fine here: boot.growPartition and
      # fileSystems."/".autoResize expand the root onto the real EBS volume.
      { virtualisation.diskSize = "auto"; }
    ];
  };
}
