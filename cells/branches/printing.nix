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
            # cups-browsed is the daemon behind the 2024 CUPS RCE chain
            # (CVE-2024-47176 and friends): it takes printer announcements off
            # the network and turns them into print queues.  systemd-analyze
            # scores it 9.6/UNSAFE.  With one known local printer there is
            # nothing to discover — add the Brother by its address instead.
            browsed.enable = false;
            # Not sharing any printer from this laptop, so don't advertise.
            browsing = false;
            # Bind the admin/IPP interface to loopback only.  Printing to a
            # networked printer is outbound and unaffected; previously the
            # nftables ruleset was the single thing keeping *:631 off the LAN.
            listenAddresses = [ "localhost:631" ];
            allowFrom = [ "localhost" ];
          };

          services.avahi = {
            enable = true;
            nssmdns4 = true;
            # Discovery only.  Publishing made the laptop announce itself over
            # multicast on a timer, which kept the wifi radio out of power save
            # on every network it joined; nothing here needs to be discoverable.
            publish.enable = false;
            # Would punch 5353 into the firewall on every interface; the
            # per-interface rules below scope it to the dock links instead.
            openFirewall = false;
          };

          # mDNS inbound only on the wired dock links, not on every wifi
          # network the laptop joins.
          networking.firewall.interfaces = {
            enp2s0f0.allowedUDPPorts = [ 5353 ];
            enp5s0.allowedUDPPorts = [ 5353 ];
          };
        }
      )
    ];
  };
}
