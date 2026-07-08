{ config, lib, ... }:
let
  isHardened = config.my.profile.security.level == "hardened";
in
{
  config.my.branches.security.nixosModules = [
    (
      { pkgs, ... }:
      {
        services = {
          dbus.enable = true;
          resolved = {
            enable = true;
            settings.Resolve = {
              DNSSEC = false;
              FallbackDNS = [
                "1.1.1.1"
                "1.0.0.1"
                "9.9.9.9"
                "149.112.112.112"
              ];
            };
          };
        };

        networking = {
          useDHCP = lib.mkDefault false;
          networkmanager = {
            enable = lib.mkDefault true;
            dns = "systemd-resolved";
            wifi.powersave = false;
            wifi.scanRandMacAddress = false; # reduces roam-triggering rescans
            plugins = [ pkgs.networkmanager-openconnect ];
            settings = {
              connectivity = {
                enabled = false;
                uri = "http://nmcheck.gnome.org/check_network_status.txt";
                interval = 300;
                response = "NetworkManager is online";
              };
              connection = {
                "wifi.cloned-mac-address" = "preserve";
              };
              device = {
                "wifi.backend" = "wpa_supplicant";
              };
            };
          };
          firewall = {
            enable = true;
            logRefusedConnections = true;
            logRefusedPackets = true;
            allowedTCPPorts = [ ];
            allowedUDPPorts = [ ];
          }
          // lib.optionalAttrs isHardened {
            allowPing = false;
          };
          nftables.enable = true;
        };

        environment.systemPackages = [ pkgs.openconnect ];
      }
    )
  ];
}
