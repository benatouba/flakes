{ myHostLib, ... }:
{
  config.my.branches.dns = {
    description = "Dendritic DNS branch for Pi-hole and Unbound services.";
    nixosModules = [
      (
        { config, lib, ... }:
        let
          cfg = config.my.dns;
        in
        {
          options.my.dns = {
            enable = myHostLib.mkDefaultOnEnable {
              inherit lib;
              description = "Pi-hole + Unbound DNS stack";
            };
            localRecords = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = { };
              example = {
                "workout.benrlschmidt.de" = "192.168.188.197";
              };
              description = ''
                Split-horizon A records served to LAN clients, as a mapping of fully
                qualified name to LAN address. These override whatever public DNS says
                for the same name.

                Use this for services that are published on a public domain but live on
                this network. Without an override, LAN clients resolve the public
                address and have to be bounced back inside by the router's NAT hairpin,
                which also means a stale negative cache upstream can make a service that
                is running perfectly well look unreachable from home. Pointing the name
                straight at the LAN address removes both dependencies. TLS still
                verifies, because the reverse proxy selects its certificate by SNI
                rather than by the address the client connected to.
              '';
            };
          };

          config = lib.mkIf cfg.enable {
            services.unbound = {
              enable = true;
              settings = {
                server = {
                  interface = [
                    "127.0.0.1"
                    "::1"
                  ];
                  port = 5335;
                  do-ip4 = true;
                  do-ip6 = true;
                  do-udp = true;
                  do-tcp = true;
                  prefetch = true;
                  harden-dnssec-stripped = true;
                  edns-buffer-size = 1232;
                };
                forward-zone = [
                  {
                    name = ".";
                    forward-tls-upstream = true;
                    forward-addr = [
                      "1.1.1.1@853#cloudflare-dns.com"
                      "1.0.0.1@853#cloudflare-dns.com"
                      "9.9.9.9@853#dns.quad9.net"
                      "149.112.112.112@853#dns.quad9.net"
                    ];
                  }
                ];
              };
            };

            services.pihole-web = {
              enable = true;
              hostName = "pi.hole";
              ports = [ 8081 ];
            };

            services.caddy = {
              enable = true;
              virtualHosts."http://pi.hole".extraConfig = ''
                @lan remote_ip private_ranges
                handle @lan {
                  reverse_proxy 127.0.0.1:8081
                }
                respond 403
              '';
            };

            services.pihole-ftl = {
              enable = true;
              openFirewallDNS = false;
              openFirewallWebserver = false;
              queryLogDeleter.enable = true;
              lists = [
                {
                  url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
                  description = "StevenBlack unified hosts";
                }
                {
                  url = "https://big.oisd.nl";
                  description = "OISD Big List";
                }
                {
                  url = "https://adaway.org/hosts.txt";
                  description = "AdAway hosts list";
                }
                {
                  url = "https://raw.githubusercontent.com/kboghdady/youTube_ads_4_pi-hole/master/youtubelist.txt";
                  description = "Community YouTube ad domains list";
                }
                {
                  url = "https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt";
                  description = "KADhosts";
                }
                {
                  url = "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts";
                  description = "FadeMind Spam hosts";
                }
                {
                  url = "https://raw.githubusercontent.com/anudeepND/blacklist/master/CoinMiner.txt";
                  description = "Anudeep CoinMiner hosts";
                }
                {
                  url = "https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt";
                  description = "Anudeep adservers hosts";
                }
                {
                  url = "https://v.firebog.net/hosts/static/w3kbl.txt";
                  description = "Firebog w3kbl hosts";
                }
                {
                  url = "https://v.firebog.net/hosts/Admiral.txt";
                  description = "Firebog Admiral hosts";
                }
                {
                  url = "https://v.firebog.net/hosts/Prigent-Ads.txt";
                  description = "Firebog Prigent-Ads hosts";
                }
              ];
              settings = {
                dns = {
                  upstreams = [ "127.0.0.1#5335" ];
                  domainNeeded = true;
                  listeningMode = "ALL";
                  # Split-horizon overrides; see my.dns.localRecords.
                  hosts = lib.mapAttrsToList (name: address: "${address} ${name}") cfg.localRecords;
                };
                webserver.api.cli_pw = true;
              };
            };

            networking.firewall = {
              allowedTCPPorts = [
                53
                80
              ];
              allowedUDPPorts = [ 53 ];
            };
          };
        }
      )
    ];
  };
}
