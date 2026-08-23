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
            listenAddresses = [ "*:631" ];
            allowFrom = [ "all" ];
          };

          services.avahi = {
            enable = true;
            nssmdns4 = true;
            # Discovery only.  Publishing made the laptop announce itself over
            # multicast on a timer, which kept the wifi radio out of power save
            # on every network it joined; nothing here needs to be discoverable.
            publish.enable = false;
            openFirewall = true;
          };

          networking.firewall.allowedUDPPorts = [ 5353 ];
        }
      )
    ];
  };
}
