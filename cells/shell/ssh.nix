{
  config,
  inputs,
  ...
}:
let
  user = config.my.user.name;
  isHardened = config.my.profile.security.level == "hardened";
  secretsRoot = toString inputs.nix-secrets;
  sshHostsPath = "${secretsRoot}/ssh-hosts.nix";
in
{

  config.my.branches.personal.hmModules = [
    (
      { lib, ... }:
      let
        hasSshHosts = builtins.pathExists sshHostsPath;
        sshHosts =
          if hasSshHosts then
            import sshHostsPath
          else
            {
              tuKey = "";
              tuProxy = { };
              hosts = { };
            };
        inherit (sshHosts) tuKey;

        noTuKeyHosts = [
          "tuebingen"
          "cirr"
          "pi-hole"
          "ec2"
          "esprimo"
        ];

        legacyToSettings =
          hostCfg:
          let
            converted =
              lib.optionalAttrs (hostCfg ? port) { Port = hostCfg.port; }
              // lib.optionalAttrs (hostCfg ? forwardAgent) { ForwardAgent = hostCfg.forwardAgent; }
              // lib.optionalAttrs (hostCfg ? forwardX11) { ForwardX11 = hostCfg.forwardX11; }
              // lib.optionalAttrs (hostCfg ? forwardX11Trusted) {
                ForwardX11Trusted = hostCfg.forwardX11Trusted;
              }
              // lib.optionalAttrs (hostCfg ? identitiesOnly) { IdentitiesOnly = hostCfg.identitiesOnly; }
              // lib.optionalAttrs (hostCfg ? identityFile) { IdentityFile = hostCfg.identityFile; }
              // lib.optionalAttrs (hostCfg ? identityAgent) { IdentityAgent = hostCfg.identityAgent; }
              // lib.optionalAttrs (hostCfg ? user) { User = hostCfg.user; }
              // lib.optionalAttrs (hostCfg ? hostname) { HostName = hostCfg.hostname; }
              // lib.optionalAttrs (hostCfg ? serverAliveInterval) {
                ServerAliveInterval = hostCfg.serverAliveInterval;
              }
              // lib.optionalAttrs (hostCfg ? serverAliveCountMax) {
                ServerAliveCountMax = hostCfg.serverAliveCountMax;
              }
              // lib.optionalAttrs (hostCfg ? sendEnv) { SendEnv = hostCfg.sendEnv; }
              // lib.optionalAttrs (hostCfg ? setEnv) { SetEnv = hostCfg.setEnv; }
              // lib.optionalAttrs (hostCfg ? compression) { Compression = hostCfg.compression; }
              // lib.optionalAttrs (hostCfg ? checkHostIP) { CheckHostIP = hostCfg.checkHostIP; }
              // lib.optionalAttrs (hostCfg ? proxyCommand) { ProxyCommand = hostCfg.proxyCommand; }
              // lib.optionalAttrs (hostCfg ? proxyJump) { ProxyJump = hostCfg.proxyJump; }
              // lib.optionalAttrs (hostCfg ? certificateFile) { CertificateFile = hostCfg.certificateFile; }
              // lib.optionalAttrs (hostCfg ? addressFamily) { AddressFamily = hostCfg.addressFamily; }
              // lib.optionalAttrs (hostCfg ? localForwards) { LocalForward = hostCfg.localForwards; }
              // lib.optionalAttrs (hostCfg ? remoteForwards) { RemoteForward = hostCfg.remoteForwards; }
              // lib.optionalAttrs (hostCfg ? dynamicForwards) { DynamicForward = hostCfg.dynamicForwards; }
              // lib.optionalAttrs (hostCfg ? addKeysToAgent) { AddKeysToAgent = hostCfg.addKeysToAgent; }
              // lib.optionalAttrs (hostCfg ? hashKnownHosts) { HashKnownHosts = hostCfg.hashKnownHosts; }
              // lib.optionalAttrs (hostCfg ? userKnownHostsFile) {
                UserKnownHostsFile = hostCfg.userKnownHostsFile;
              }
              // lib.optionalAttrs (hostCfg ? controlMaster) { ControlMaster = hostCfg.controlMaster; }
              // lib.optionalAttrs (hostCfg ? controlPath) { ControlPath = hostCfg.controlPath; }
              // lib.optionalAttrs (hostCfg ? controlPersist) { ControlPersist = hostCfg.controlPersist; }
              // lib.optionalAttrs (hostCfg ? kexAlgorithms) { KexAlgorithms = hostCfg.kexAlgorithms; };
          in
          converted // (hostCfg.extraOptions or { });

        mkHost =
          name: hostCfg:
          legacyToSettings (
            hostCfg // (if !builtins.elem name noTuKeyHosts then { identityFile = tuKey; } else { })
          );

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

        settings = builtins.mapAttrs mkHost sshHosts.hosts // {
          "*" = {
            inherit (defaultOptions)
              AddKeysToAgent
              IdentitiesOnly
              HashKnownHosts
              StrictHostKeyChecking
              VerifyHostKeyDNS
              ServerAliveInterval
              ServerAliveCountMax
              Compression
              ForwardAgent
              ForwardX11
              PasswordAuthentication
              PubkeyAuthentication
              ;
          }
          // lib.optionalAttrs isHardened {
            KexAlgorithms = "sntrup761x25519-sha512,sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org";
            HostKeyAlgorithms = "ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256";
            Ciphers = "chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com";
          };

          "tu-* !tu-proxy" = {
            ProxyJump = "tu-proxy";
          };

          tu-proxy = legacyToSettings (sshHosts.tuProxy // { identityFile = tuKey; });
        };
      in
      {
        assertions = [
          {
            assertion = hasSshHosts;
            message = "The personal branch requires ${sshHostsPath} to exist.";
          }
        ];
      }
      // lib.optionalAttrs hasSshHosts {
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
            "ec2-matrix" = {
              path = "/home/${user}/.ssh/ec2-matrix.pem";
              mode = "0600";
            };
          };
        };

        home.file.".ssh/id_ed25519.pub".text =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHwt/9sYFxYhYB8kAeaOraASje7EqQusTCJtvvNVt+hx benschmidt@live.de\n";
        home.file.".ssh/tubklima_laptop.pub".text =
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDEkZsCjzAujJXehNC0BwJwT5KAS8PEIRjqHLhlcUKx02ahTOrASWhtkXu515lnUFnc3UDm+NarXRJOjKmoR9s/tBR3pgj1PcYE4PCGxw7eRmddQA4wGPJDvufiJJsmZHxON8d8FyvoUmS0T2s52ljVO1ADeAzmT/nxFhvUlAXtRE8gHimThH0Xs8BgvYTX4wDeRIiLcVf762Tn7EAq2dgmx2g3isaBioeAt5haXU4Iz/G1oSkz53bQd6vr+viYXUnNM/76nKb4nuuf2cPRXZlcIcojOO47q/6Lo92nUZBzeaSsM4/tk3OD95kEPkUsXpvKZahX9bBA2InxFBzUX4nFs/n+fZRrAbTxF1/R8xSE+dVWW7vq/jHLn51MRPpRexoCvYe+VkIceYLWEXJ5DNDiAEWYUMZMsqmCYAmJq/aLT9EZQ690hkNnatSeSRB25AY9kvzvy4R/eHDk6I5xDFp3d3I6DI3MUVDtlwkvPd4HO3hS0IJMjBvLYsPLRhQ5Dqk= ben@thinkpad\n";

        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          inherit settings;
        };
      }
    )
  ];
}
