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
            publish.enable = true;
            publish.userServices = true;
            openFirewall = true;
          };

          networking.firewall.allowedUDPPorts = [ 5353 ];
        }
      )
    ];
  };
}
