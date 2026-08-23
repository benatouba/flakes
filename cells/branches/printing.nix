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
            browsing = true;
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
