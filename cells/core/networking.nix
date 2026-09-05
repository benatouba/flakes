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
              # "allow-downgrade" rather than true, specifically because of the
              # home Pi-hole: it blocks by returning forged answers, and strict
              # validation turns every blocked *signed* domain into a SERVFAIL
              # instead of a clean block.  Downgrade mode validates when the
              # resolver path actually supports DNSSEC and quietly falls back
              # when it doesn't.  Strictly better than off, and by design
              # defeatable by an active MITM that strips DNSSEC — the honest
              # middle ground for a laptop that roams.
              DNSSEC = "allow-downgrade";
              # LLMNR answers name lookups from anyone on the local link and is
              # the standard credential-relay foothold on untrusted networks.
              # Nothing here needs it; mDNS covers local discovery.
              LLMNR = false;
              # Encrypt DNS where the resolver supports it.  "opportunistic"
              # rather than "true" so captive portals still work.
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

        # PMTUD depends on ICMP "fragmentation needed" getting back to us, and
        # plenty of hotel APs, captive portals and VPN concentrators drop it.
        # The symptom is nasty to diagnose: the handshake succeeds and small
        # requests work, then anything larger hangs. Mode 1 turns on probing
        # only after such a black hole is detected, so it costs nothing on a
        # healthy link.
        #
        # The other network sysctls are split by intent: congestion control and
        # the qdisc sit with the rest of the throughput tuning in
        # cells/core/power.nix, and the anti-spoofing set in
        # cells/core/security.nix.
        boot.kernel.sysctl."net.ipv4.tcp_mtu_probing" = 1;

        networking = {
          useDHCP = lib.mkDefault false;
          networkmanager = {
            enable = lib.mkDefault true;
            dns = "systemd-resolved";
            # Left unset on purpose: TLP owns wifi power management via
            # WIFI_PWR_ON_{AC,BAT}, and a value here would fight it on every
            # connection activation.
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
