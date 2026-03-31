{ config, ... }:
let
  user = config.my.user.name;
in
{
  config.my.nixosModules = [{
    environment.persistence."/persist" = {
      hideMounts = true;

      directories = [
        "/etc/nixos"
        "/etc/ssh"
        "/etc/NetworkManager/system-connections"
        "/var/lib/nixos"
        "/var/lib/NetworkManager"
        "/var/lib/bluetooth"
        "/var/lib/auto-cpufreq"
        "/var/log"
        "/var/lib/systemd"
      ];

      files = [
        "/etc/machine-id"
      ];
    };

    systemd.tmpfiles.rules = [
      "d /persist/home 0755 root root -"
      "d /persist/home/${user} 0700 ${user} users -"
      "d /persist/passwords 0700 root root -"
      "d /persist/sops 0755 root root -"
      "d /persist/sops/age 0700 ${user} users -"
    ];
  }];
}
