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

  inherit (myHostLib) identity;
  sshKey = identity.sshPublicKey;
in
{
  config.my.hosts.esprimo = {
    system = "x86_64-linux";
    includeProfileBranches = false;
    branches = [
      "secrets"
      "server"
      "dns"
      "finance"
      "paperless"
      "wger"
      "ddns"
    ];

    nixosModules = [
      (
        {
          pkgs,
          ...
        }:
        {
          # LAN clients resolve the public name locally (split horizon). Set here,
          # not in the dns branch, because the record belongs to this host only.
          my.dns.localRecords.${identity.workoutDomain} = identity.lanIp;

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

          sops.age = {
            keyFile = lib.mkForce null;
            sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
          };

          security.sudo.extraConfig = ''
            ${cfg.user.name} ALL=(root) NOPASSWD: /bin/sh -c exec\ env\ -i\ PATH=*\ *\ sh\ nix-env\ -p\ /nix/var/nix/profiles/system\ --set\ /nix/store/*-nixos-system-esprimo-*
            ${cfg.user.name} ALL=(root) NOPASSWD: /bin/sh -c *\ /nix/store/*-nixos-system-esprimo-*/bin/switch-to-configuration\ *
          '';

        }
      )
    ];
  };

  # workout CNAME on Netlify DNS (no dynamic API); moving part lives at deSEC.
  config.my.ddns.hostname = identity.ddnsHostname;

  config.my.wger = {
    enable = true;
    domain = identity.workoutDomain;
    siteUrl = "https://${identity.workoutDomain}";
    trustedOrigins = [
      "http://127.0.0.1:8310"
      "http://localhost:8310"
      "http://esprimo:8310"
      "http://${identity.lanIp}:8310"
    ];
    port = 8310;
    public = {
      enable = true;
      domain = identity.workoutDomain;
    };
    registration = {
      allowRegistration = true;
      allowGuestUsers = false;
      requireAdminApproval = true;
    };
    routine = {
      maxDurationDays = 3650;
    };
    backup = {
      enable = true;
      schedule = "daily";
      keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
    };
  };

  config.my.finance = {
    enable = true;
    domain = "finance.esprimo";
    title = "Finance";
    port = 5000;
    importSchedule = "hourly";
    postbank = {
      enable = true;
      sourceDir = "/var/lib/finance/sources/postbank";
      outputDir = "/var/lib/finance/imports/postbank";
      ledgerAccount = "Assets:Checking";
      incomeAccount = "Income:Unknown";
      expenseAccount = "Expenses:Unknown";
    };
    paperless = {
      enable = true;
      consumptionDir = "/var/lib/paperless/consume/import/finance";
      mediaDir = "/var/lib/paperless/media/documents/originals";
      baseUrl = "http://paperless.esprimo";
    };
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
