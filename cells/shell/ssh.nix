{ config, ... }:
let
  user = config.my.user.name;
in
{
  config.my.hmModules = [({ config, ... }: {
    sops = {
      secrets = {
        ssh_id_ed25519 = {
          path = "/home/${user}/.ssh/id_ed25519";
          mode = "0600";
        };
        ssh_tubklima_laptop = {
          path = "/home/${user}/.ssh/tubklima_laptop";
          mode = "0600";
        };
      };
    };

    home.file.".ssh/id_ed25519.pub".text = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHwt/9sYFxYhYB8kAeaOraASje7EqQusTCJtvvNVt+hx benschmidt@live.de\n";
    home.file.".ssh/tubklima_laptop.pub".text = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDEkZsCjzAujJXehNC0BwJwT5KAS8PEIRjqHLhlcUKx02ahTOrASWhtkXu515lnUFnc3UDm+NarXRJOjKmoR9s/tBR3pgj1PcYE4PCGxw7eRmddQA4wGPJDvufiJJsmZHxON8d8FyvoUmS0T2s52ljVO1ADeAzmT/nxFhvUlAXtRE8gHimThH0Xs8BgvYTX4wDeRIiLcVf762Tn7EAq2dgmx2g3isaBioeAt5haXU4Iz/G1oSkz53bQd6vr+viYXUnNM/76nKb4nuuf2cPRXZlcIcojOO47q/6Lo92nUZBzeaSsM4/tk3OD95kEPkUsXpvKZahX9bBA2InxFBzUX4nFs/n+fZRrAbTxF1/R8xSE+dVWW7vq/jHLn51MRPpRexoCvYe+VkIceYLWEXJ5DNDiAEWYUMZMsqmCYAmJq/aLT9EZQ690hkNnatSeSRB25AY9kvzvy4R/eHDk6I5xDFp3d3I6DI3MUVDtlwkvPd4HO3hS0IJMjBvLYsPLRhQ5Dqk= ben@thinkpad\n";

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      matchBlocks = let
        tuKey = "~/.ssh/tubklima_laptop";
        tuProxy = {
          hostname = "130.149.72.106";
          user = "root";
          identityFile = tuKey;
        };
      in {
        "*" = {
          extraOptions = {
            AddKeysToAgent = "yes";
            IdentitiesOnly = "yes";
          };
        };

        "tu-*" = {
          proxyJump = "tu-proxy";
        };

        tu-proxy = tuProxy;

        tu-hpc = {
          hostname = "hpc.klima.tu-berlin.de";
          user = "root";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
          forwardX11 = true;
          localForwards = [
            { bind.port = 3000; host.address = "localhost"; host.port = 3000; }
            { bind.port = 8086; host.address = "localhost"; host.port = 8086; }
            { bind.port = 8886; host.address = "localhost"; host.port = 3000; }
            { bind.port = 8887; host.address = "localhost"; host.port = 3100; }
            { bind.port = 8888; host.address = "localhost"; host.port = 9090; }
          ];
        };

        tu-hpc2 = {
          hostname = "hpc2.klima.tu-berlin.de";
          user = "schmidt";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
          forwardX11 = true;
          localForwards = [
            { bind.port = 8086; host.address = "localhost"; host.port = 8086; }
            { bind.port = 8886; host.address = "localhost"; host.port = 3000; }
            { bind.port = 8887; host.address = "localhost"; host.port = 3100; }
            { bind.port = 8888; host.address = "localhost"; host.port = 9090; }
            { bind.port = 8889; host.address = "localhost"; host.port = 9100; }
          ];
        };

        tu-pve01 = {
          hostname = "pve01.klima.tu-berlin.de";
          user = "root";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
        };

        tu-pve01b = {
          hostname = "130.149.72.79";
          user = "root";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
        };

        tu-pve02 = {
          hostname = "pve02.klima.tu-berlin.de";
          user = "root";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
        };

        tu-pve02b = {
          hostname = "pve02b.klima.tu-berlin.de";
          user = "root";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
        };

        tu-gitlab = {
          hostname = "130.149.72.96";
          user = "root";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
          forwardX11 = true;
        };

        tu-collabora = {
          hostname = "130.149.72.123";
          user = "root";
          identityFile = tuKey;
        };

        tu-fs = {
          hostname = "130.149.72.63";
          user = "root";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
          forwardX11 = true;
        };

        tu-fs-bck = {
          hostname = "130.149.72.64";
          user = "root";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
        };

        tu-ftp = {
          hostname = "130.149.72.81";
          user = "root";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
        };

        tu-salt = {
          hostname = "130.149.72.79";
          user = "root";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
          localForwards = [
            { bind.port = 8086; host.address = "localhost"; host.port = 8086; }
            { bind.port = 8888; host.address = "localhost"; host.port = 3000; }
            { bind.port = 8889; host.address = "localhost"; host.port = 3100; }
            { bind.port = 8890; host.address = "localhost"; host.port = 9100; }
            { bind.port = 8891; host.address = "localhost"; host.port = 9090; }
          ];
        };

        tu-web = {
          hostname = "130.149.72.68";
          user = "root";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
          localForwards = [
            { bind.port = 8081; host.address = "localhost"; host.port = 8081; }
            { bind.port = 8082; host.address = "localhost"; host.port = 8082; }
            { bind.port = 8085; host.address = "localhost"; host.port = 8085; }
          ];
        };

        tu-doku = {
          hostname = "doku.klima.tu-berlin.de";
          user = "root";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
        };

        tu-web-bck = {
          hostname = "130.149.72.123";
          user = "root";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
        };

        tu-web-oldkb = {
          hostname = "130.149.72.69";
          user = "root";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
        };

        tuebingen = {
          hostname = "134.2.5.40";
          user = "esd_guest";
          port = 6307;
        };

        cirr = {
          hostname = "cirrus.geo.hu-berlin.de";
          user = "smidbenq";
        };

        tu-dms = {
          hostname = "130.149.72.41";
          user = "schmidt";
          identityFile = tuKey;
          forwardX11 = true;
        };

        tu-dms-bck = {
          hostname = "130.149.72.34";
          user = "root";
          proxyJump = "tu-proxy";
        };

        pi-hole = {
          hostname = "192.168.188.31";
          user = "pi";
        };

        ec2 = {
          hostname = "52.58.141.180";
          user = "ec2-user";
          identityFile = "~/.ssh/ec2-demo.pem";
        };

        tu-desktop = {
          hostname = "130.149.72.50";
          user = "ben";
          proxyJump = "tu-proxy";
        };

        tu-db1 = {
          hostname = "130.149.72.97";
          user = "root";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
        };

        tu-krake = {
          hostname = "130.149.72.46";
          user = "root";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
        };

        tu-row = {
          hostname = "130.149.72.110";
          user = "frog";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
        };

        tu-uco = {
          hostname = "130.149.72.59";
          user = "root";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
        };

        tu-uco-stage = {
          hostname = "130.149.72.54";
          user = "root";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
        };

        tu-sentinel = {
          hostname = "130.149.72.65";
          user = "root";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
        };

        tu-data = {
          hostname = "130.149.72.77";
          user = "root";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
        };

        tu-cumulus = {
          hostname = "cumulus.klima.tu-berlin.de";
          user = "root";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
        };

        tu-cumulus-data = {
          hostname = "130.149.72.69";
          user = "root";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
        };

        tu-proc = {
          hostname = "130.149.72.30";
          user = "root";
          identityFile = tuKey;
          proxyJump = "tu-proxy";
        };

        tu-maress = {
          hostname = "130.149.72.75";
          user = "root";
          identityFile = tuKey;
        };

        oekofen-pi = {
          hostname = "192.168.178.91";
          user = "admin";
          identityFile = tuKey;
        };
      };
    };
  })];
}
