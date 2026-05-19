{ config, ... }:
{
  config.my.branches.vpn.nixosModules = [
    (
      { pkgs, ... }:
      let
        nordvpnPkg = pkgs.callPackage ../../pkgs/nordvpn { };
      in
      {
        nixpkgs.config.allowUnfree = true;

        environment.systemPackages = with pkgs; [
          nordvpnPkg
          wireguard-tools
        ];

        users = {
          groups.nordvpn = { };
          users.${config.my.user.name}.extraGroups = [ "nordvpn" ];
        };

        systemd = {
          sockets.nordvpnd = {
            description = "NordVPN Daemon Socket";
            wantedBy = [ "sockets.target" ];
            partOf = [ "nordvpnd.service" ];
            socketConfig = {
              ListenStream = "/run/nordvpn/nordvpnd.sock";
              SocketGroup = "nordvpn";
              SocketMode = "0770";
              DirectoryMode = "0750";
            };
          };

          services.nordvpnd = {
            description = "NordVPN Daemon";
            wantedBy = [ "multi-user.target" ];
            requires = [ "nordvpnd.socket" ];
            after = [ "network-pre.target" ];
            path = with pkgs; [
              iptables
              iproute2
              procps
            ];
            serviceConfig = {
              ExecStart = "${nordvpnPkg}/bin/nordvpnd";
              NonBlocking = true;
              KillMode = "process";
              Restart = "on-failure";
              RestartSec = 5;
              RuntimeDirectory = "nordvpn";
              RuntimeDirectoryMode = "0750";
              Group = "nordvpn";
            };
          };

          tmpfiles.rules = [
            "d /usr/lib 0755 root root -"
            "L+ /usr/lib/nordvpn - - - - ${nordvpnPkg}/lib/nordvpn"
            "d /run/nordvpn 0770 root nordvpn"
            "d /var/lib/nordvpn 0750 root nordvpn"
            "d /var/lib/nordvpn/data 0750 root nordvpn"
          ];
        };

        systemd.services.nordvpn-gateway = {
          description = "Configure NordVPN client";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [
            "network-online.target"
            "nordvpnd.service"
            "pihole-ftl.service"
            "unbound.service"
          ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            Environment = "HOME=/root";
          };
          path = with pkgs; [
            coreutils
            nordvpnPkg
          ];
          script = ''
            set -u

            run() {
              "$@" || true
            }

            for _ in $(seq 1 30); do
              if nordvpn status >/dev/null 2>&1; then
                break
              fi
              sleep 1
            done

            run nordvpn set technology NORDLYNX
            run nordvpn set lan-discovery enabled
            run nordvpn set dns disabled
            run nordvpn set analytics disabled
            run nordvpn set threatprotectionlite disabled
            # Keep host management and local DNS stable while NordVPN is active.
            run nordvpn set routing disabled
            run nordvpn set autoconnect enabled
            # Keep NordVPN firewall features off; NixOS firewall stays authoritative.
            run nordvpn set firewall disabled
            run nordvpn set killswitch disabled
            run nordvpn connect
          '';
        };
      }
    )
  ];
}
