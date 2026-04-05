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
              DNS = [
                "1.1.1.1#cloudflare-dns.com"
                "1.0.0.1#cloudflare-dns.com"
              ];
              DNSOverTLS = "opportunistic";
              DNSSEC = "allow-downgrade";
              FallbackDNS = [
                "9.9.9.9#dns.quad9.net"
                "149.112.112.112#dns.quad9.net"
              ];
              Domains = [ "~." ];
            };
          };
        };

        networking = {
          useDHCP = lib.mkDefault false;
          nameservers = [
            "1.1.1.1#cloudflare-dns.com"
            "1.0.0.1#cloudflare-dns.com"
          ];
          networkmanager = {
            enable = lib.mkDefault true;
            dns = "systemd-resolved";
            plugins = [ pkgs.networkmanager-openconnect ];
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
