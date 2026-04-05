{
  config,
  inputs,
  lib,
  ...
}:
let
  user = config.my.user.name;
  isHardened = config.my.profile.security.level == "hardened";
  secretsRoot = toString inputs.nix-secrets;
  sshHostsPath = "${secretsRoot}/ssh-hosts.nix";
  sshHosts = import sshHostsPath;
  inherit (sshHosts) tuKey;

  noTuKeyHosts = [
    "tuebingen"
    "cirr"
    "pi-hole"
    "ec2"
  ];

  mkHost =
    name: hostCfg:
    hostCfg // (if !builtins.elem name noTuKeyHosts then { identityFile = tuKey; } else { });

  defaultOptions = {
    AddKeysToAgent = "yes";
    IdentitiesOnly = "yes";
    HashKnownHosts = "yes";
    StrictHostKeyChecking = "ask";
    VerifyHostKeyDNS = "yes";
    ServerAliveInterval = "30";
    ServerAliveCountMax = "3";
    Compression = "yes";
    ForwardAgent = "no";
    ForwardX11 = "no";
    PasswordAuthentication = "no";
    PubkeyAuthentication = "yes";
  };

  matchBlocks = builtins.mapAttrs mkHost sshHosts.hosts // {
    "*" = {
      extraOptions =
        defaultOptions
        // lib.optionalAttrs isHardened {
          KexAlgorithms = "sntrup761x25519-sha512,sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org";
          HostKeyAlgorithms = "ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256";
          Ciphers = "chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com";
        };
    };

    "tu-* !tu-proxy" = {
      proxyJump = "tu-proxy";
    };

    tu-proxy = sshHosts.tuProxy // {
      identityFile = tuKey;
    };
  };
in
assert builtins.pathExists sshHostsPath;
{

  config.my.branches.security.hmModules = [
    (_: {
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
          # To manage the EC2 key via sops, add ssh_ec2_demo to secrets.yaml
          # then uncomment:
          # ssh_ec2_demo = {
          #   path = "/home/${user}/.ssh/ec2-demo.pem";
          #   mode = "0600";
          # };
        };
      };

      home.file.".ssh/id_ed25519.pub".text =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHwt/9sYFxYhYB8kAeaOraASje7EqQusTCJtvvNVt+hx benschmidt@live.de\n";
      home.file.".ssh/tubklima_laptop.pub".text =
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDEkZsCjzAujJXehNC0BwJwT5KAS8PEIRjqHLhlcUKx02ahTOrASWhtkXu515lnUFnc3UDm+NarXRJOjKmoR9s/tBR3pgj1PcYE4PCGxw7eRmddQA4wGPJDvufiJJsmZHxON8d8FyvoUmS0T2s52ljVO1ADeAzmT/nxFhvUlAXtRE8gHimThH0Xs8BgvYTX4wDeRIiLcVf762Tn7EAq2dgmx2g3isaBioeAt5haXU4Iz/G1oSkz53bQd6vr+viYXUnNM/76nKb4nuuf2cPRXZlcIcojOO47q/6Lo92nUZBzeaSsM4/tk3OD95kEPkUsXpvKZahX9bBA2InxFBzUX4nFs/n+fZRrAbTxF1/R8xSE+dVWW7vq/jHLn51MRPpRexoCvYe+VkIceYLWEXJ5DNDiAEWYUMZMsqmCYAmJq/aLT9EZQ690hkNnatSeSRB25AY9kvzvy4R/eHDk6I5xDFp3d3I6DI3MUVDtlwkvPd4HO3hS0IJMjBvLYsPLRhQ5Dqk= ben@thinkpad\n";

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        inherit matchBlocks;
      };
    })
  ];
}
