{ config, lib, pkgs, user, ... }:
{
  environment.persistence."/persist" = {
    hideMounts = true;

    directories = [
      "/etc/ssh"                                  # host keys
      "/etc/NetworkManager/system-connections"     # NM connection files
      "/var/lib/nixos"                             # uid/gid map (CRITICAL)
      "/var/lib/NetworkManager"                    # wifi passwords
      "/var/lib/bluetooth"                         # bluetooth pairings
      "/var/lib/systemd/coredump"                  # coredumps
      "/var/lib/auto-cpufreq"                      # learned profiles
      "/var/log"                                   # system logs
    ];

    files = [
      "/etc/machine-id"                            # systemd machine-id (CRITICAL)
    ];
  };

  # Ensure persist home directory exists with correct ownership
  systemd.tmpfiles.rules = [
    "d /persist/home 0755 root root -"
    "d /persist/home/${user} 0700 ${user} users -"
  ];
}
