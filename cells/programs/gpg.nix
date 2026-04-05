_: {
  config.my.branches.security.hmModules = [
    (
      { pkgs, ... }:
      {
        programs.gpg.package = pkgs.gnupg;
        services = {
          gpg-agent = {
            enable = true;
            pinentry.package = pkgs.pinentry-gnome3;
          };
        };
      }
    )
  ];
}
