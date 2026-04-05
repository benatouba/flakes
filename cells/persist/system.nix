{ config, ... }:
let
  user = config.my.user.name;
in
{
  config.my.branches.security.nixosModules = [
    {
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
        "d /persist/sops 0750 root users -"
        "d /persist/sops/age 0750 root users -"
        "f /persist/sops/age/keys.txt 0640 root users -"
      ];
    }
  ];
}
