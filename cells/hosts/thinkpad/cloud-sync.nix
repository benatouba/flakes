_: {
  config.my.hosts.thinkpad.hmModules = [
    (
      { config, ... }:
      {
        # One client can manage multiple university accounts. Account URLs,
        # usernames and browser-issued tokens remain runtime-only; see
        # cloud-sync.md alongside this module. Never generate nextcloud.cfg
        # in the Nix store.
        services.nextcloud-client = {
          enable = true;
          startInBackground = true;
        };

        # The upstream service runs the binary but does not add it to the user
        # profile; install it for the launcher and interactive account setup.
        home.packages = [ config.services.nextcloud-client.package ];

        # documents and the GNOME keyring are already persisted by the persist
        # branch. Keep the writable account/folder configuration across boots.
        home.persistence."/persist".directories = [
          ".config/Nextcloud"
        ];
      }
    )
  ];
}
