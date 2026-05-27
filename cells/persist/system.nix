{ config, ... }:
let
  user = config.my.user.name;
in
{
  config.my.branches.persist.nixosModules = [
    {
      users.groups.sops-keys.members = [ user ];

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
        "d /persist/sops 0750 root sops-keys -"
        "d /persist/sops/age 0750 root sops-keys -"
        "f /persist/sops/age/keys.txt 0640 root sops-keys -"
      ];
    }
  ];
}
