_: {
  config.my.branches.desktop.nixosModules = [
    (
      { pkgs, ... }:
      {
        services = {
          # No `dbus.packages = [ pkgs.gcr* ]` here: gnome-keyring.enable
          # already registers gnome-keyring and gcr_3 itself.
          gnome.gnome-keyring.enable = true;
          greetd = {
            enable = true;
            settings = {
              default_session = {
                command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --asterisks --cmd start-hyprland";
                user = "greeter";
              };
            };
          };
        };

        security.pam.services.greetd.enableGnomeKeyring = true;
      }
    )
  ];
}
