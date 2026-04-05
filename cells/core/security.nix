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
