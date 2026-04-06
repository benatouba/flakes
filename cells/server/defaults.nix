{ config, ... }:
let
  user = config.my.user.name;
in
{
  config.my.branches.server.nixosModules = [
    (
      { lib, pkgs, ... }:
      {
        time.timeZone = "Europe/Berlin";
        i18n.defaultLocale = "en_US.UTF-8";

        users.users.${user} = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
        };

        services.openssh = {
          enable = true;
          settings = {
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
            PermitRootLogin = "prohibit-password";
          };
        };

        networking = {
          useDHCP = lib.mkDefault true;
          networkmanager.enable = lib.mkForce false;
          firewall = {
            enable = true;
            allowedTCPPorts = [
              22
              80
              443
              8448
            ];
          };
        };

        services.fail2ban.enable = true;

        nix.settings = {
          auto-optimise-store = true;
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          trusted-users = [
            "root"
            "@wheel"
          ];
        };

        environment.systemPackages = with pkgs; [
          curl
          git
          htop
          tmux
          wget
        ];

        system.stateVersion = lib.mkDefault "25.05";
      }
    )
  ];
}
