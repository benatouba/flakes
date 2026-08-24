{ config, lib, ... }:
let
  isHardened = config.my.profile.security.level == "hardened";
in
{
  config.my.branches.security.nixosModules = [
    (
      { pkgs, ... }:
      {
        security = {
          rtkit.enable = true;
          protectKernelImage = true;
          # NOTE: this currently enforces nothing, and that is not fixable by
          # adding pkgs.apparmor-profiles.  All 198 upstream profiles attach to
          # /usr (172) or /opt (13) paths; none reference /nix/store, so on
          # NixOS they match no binary at all.  76 of them are additionally
          # flags=(unconfined) stubs that enforce nothing even on Debian.
          # Kept enabled so that NixOS modules which do ship their own policies
          # are honoured if one is added later — but do not read this line as
          # meaning desktop apps are confined.  Real confinement here comes
          # from systemd service hardening, not AppArmor.
          apparmor.enable = true;

          polkit.extraConfig = ''
            polkit.addRule(function(action, subject) {
              if (action.id == "org.freedesktop.policykit.exec" &&
                  action.lookup("program") == "${pkgs.tlp}/bin/tlp" &&
                  subject.isInGroup("wheel")) {
                return polkit.Result.AUTH_SELF;
              }
            });
          '';

          sudo = {
            enable = true;
            execWheelOnly = true;
            wheelNeedsPassword = true;
            extraConfig = ''
              Defaults timestamp_timeout=5
              Defaults passwd_tries=3
              Defaults env_reset
              Defaults use_pty
              Defaults logfile="/var/log/sudo.log"
            '';
          };
        };

        services.openssh.enable = false;

        # Keep firmware current.  The P14s has good LVFS coverage, and this is
        # how UEFI and Thunderbolt/USB4 fixes actually land — `fwupdmgr
        # refresh && fwupdmgr update`.
        services.fwupd.enable = true;

        networking = {
          firewall = {
            enable = true;
            logRefusedConnections = true;
            # Off on purpose: on any busy/public network this logs every
            # stray broadcast, waking the CPU and writing to the journal
            # continuously.  Refused *connections* are still logged.
            logRefusedPackets = false;
            allowedTCPPorts = [ ];
            allowedUDPPorts = [ ];
          }
          // lib.optionalAttrs isHardened {
            allowPing = false;
          };
          nftables.enable = true;
        };

        boot.kernel.sysctl = {
          "kernel.kptr_restrict" = 2;
          "kernel.yama.ptrace_scope" = 1;
          "kernel.unprivileged_bpf_disabled" = 1;
          "kernel.sysrq" = 0;
          "net.ipv4.conf.all.rp_filter" = 1;
          "net.ipv4.conf.default.rp_filter" = 1;
          "net.ipv4.conf.all.log_martians" = 1;
          "net.ipv4.conf.default.log_martians" = 1;
          "net.ipv4.tcp_syncookies" = 1;
          "net.ipv4.conf.all.accept_redirects" = 0;
          "net.ipv4.conf.default.accept_redirects" = 0;
          "net.ipv4.conf.all.send_redirects" = 0;
          "net.ipv4.conf.default.send_redirects" = 0;
          "net.ipv6.conf.all.accept_redirects" = 0;
          "net.ipv6.conf.default.accept_redirects" = 0;
        }
        // lib.optionalAttrs isHardened {
          "kernel.dmesg_restrict" = 1;
          "kernel.perf_event_paranoid" = 3;
          "net.ipv4.conf.all.accept_source_route" = 0;
          "net.ipv4.conf.default.accept_source_route" = 0;
          "net.ipv6.conf.all.accept_source_route" = 0;
          "net.ipv6.conf.default.accept_source_route" = 0;
          "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
          "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
        };

      }
    )
  ];
}
