{ ... }:
{
  config.my.nixosModules = [({ pkgs, ... }: {
    security.rtkit.enable = true;
    security.protectKernelImage = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.policykit.exec" &&
            action.lookup("program") == "${pkgs.tlp}/bin/tlp" &&
            subject.isInGroup("wheel")) {
          return polkit.Result.AUTH_SELF;
        }
      });
    '';
    security.sudo = {
      enable = true;
      extraConfig = ''
        Defaults timestamp_timeout=5
      '';
    };

    boot.kernel.sysctl = {
      "kernel.kptr_restrict" = 2;
      "kernel.yama.ptrace_scope" = 1;
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.all.log_martians" = 1;
    };
  })];
}
