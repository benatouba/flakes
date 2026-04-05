_: {
  config.my.branches.desktop.nixosModules = [
    (
      { pkgs, ... }:
      {
        services = {
          gnome.gnome-keyring.enable = true;
          dbus.packages = [ pkgs.gcr ];
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
