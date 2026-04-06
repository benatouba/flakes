{ config, lib, ... }:
let
  cfg = config.my;
  hostCfg = cfg.hosts.ec2;

  selectedBranchNames = lib.unique hostCfg.branches;
  knownBranchNames = builtins.attrNames cfg.branches;
  unknownBranches = builtins.filter (
    name: !(builtins.elem name knownBranchNames)
  ) selectedBranchNames;
  selectedBranches =
    if unknownBranches != [ ] then
      throw (
        "Unknown branch names for ec2 in my.hosts.ec2.branches: "
        + lib.concatStringsSep ", " unknownBranches
      )
    else
      map (name: cfg.branches.${name}) selectedBranchNames;

  branchNixosModules = lib.concatMap (branchCfg: branchCfg.nixosModules) selectedBranches;
in
{
  config.my.hosts.ec2 = {
    system = "x86_64-linux";
    branches = [
      "server"
      "matrix"
    ];
    nixosModules = [
      (
        { ... }:
        {
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
    modules = branchNixosModules ++ hostCfg.nixosModules ++ hostCfg.hardwareModules;
  };
}
