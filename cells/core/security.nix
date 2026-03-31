{ ... }:
{
  config.my.nixosModules = [({ pkgs, ... }: {
    security.rtkit.enable = true;
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
  })];
}
