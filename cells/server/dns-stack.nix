_: {
  config.my.branches.dns.nixosModules = [
    (
      { ... }:
      {
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
          ports = [ 80 ];
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
      }
    )
  ];
}
