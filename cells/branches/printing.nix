_: {
  config.my.branches.printing = {
    description = "CUPS printing with Brother HL-L2375DW support.";

    nixosModules = [
      (
        { pkgs, ... }:
        {
          services.printing = {
            enable = true;
            drivers = [ pkgs.brlaser ];
            # browsed off: behind 2024 CUPS RCE (CVE-2024-47176), auto-makes queues.
            # Single known printer; add the Brother by address instead.
            browsed.enable = false;
            # Not sharing any printer from this laptop, so don't advertise.
            browsing = false;
            # Loopback-only IPP; outbound printing unaffected, keeps :631 off LAN.
            listenAddresses = [ "localhost:631" ];
            allowFrom = [ "localhost" ];
          };

          services.avahi = {
            enable = true;
            nssmdns4 = true;
            # No publishing: multicast announcements keep wifi out of power save.
            publish.enable = false;
            # Firewall scoped to dock links below instead of every interface.
            openFirewall = false;
          };

          # mDNS inbound on wired dock links only, not on wifi.
          networking.firewall.interfaces = {
            enp2s0f0.allowedUDPPorts = [ 5353 ];
            enp5s0.allowedUDPPorts = [ 5353 ];
          };
        }
      )
    ];
  };
}
