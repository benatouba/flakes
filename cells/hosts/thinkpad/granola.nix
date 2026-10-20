_: {
  config.my.hosts.thinkpad.hmModules = [
    (
      { inputs, pkgs, ... }:
      {
        # Unofficial Linux repackaging; meeting data is processed by Granola's cloud.
        home.packages = [ inputs.granola.packages.${pkgs.stdenv.hostPlatform.system}.granola ];

        # Home Manager owns mimeapps.list, so declare the OAuth callback handler here.
        xdg.mimeApps.defaultApplications."x-scheme-handler/granola" = "granola.desktop";
      }
    )
  ];
}
