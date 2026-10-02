{ lib, ... }:
{
  config.my.branches.base.nixosModules = [
    (
      { pkgs, ... }:
      {
        services = {
          dbus.enable = true;
          resolved = {
            enable = true;
            settings.Resolve = {
              # allow-downgrade validates when supported, falls back for Pi-hole blocks.
              # Better than off; an active MITM stripping DNSSEC still defeats it.
              DNSSEC = "allow-downgrade";
              # LLMNR off: link-local credential-relay risk; mDNS covers discovery.
              LLMNR = false;
              # Opportunistic DoT so captive portals still work.
              DNSOverTLS = "opportunistic";
              FallbackDNS = [
                "1.1.1.1"
                "1.0.0.1"
                "9.9.9.9"
                "149.112.112.112"
              ];
            };
          };
        };

        # Probes MTU black holes (hotel APs/VPNs dropping ICMP); free on healthy links.
        # Throughput tuning lives in power.nix, anti-spoofing in security.nix.
        boot.kernel.sysctl."net.ipv4.tcp_mtu_probing" = 1;

        networking = {
          useDHCP = lib.mkDefault false;
          networkmanager = {
            enable = lib.mkDefault true;
            dns = "systemd-resolved";
            # Unset: TLP owns wifi power via WIFI_PWR_ON_*; a value here would fight it.
            wifi.powersave = null;
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
        };

        environment.systemPackages = [ pkgs.openconnect ];
      }
    )
  ];
}
