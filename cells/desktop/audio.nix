_: {
  config.my.branches.desktop.nixosModules = [
    (
      { pkgs, ... }:
      {
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
          wireplumber.extraConfig."99-raise-volume-limit" = {
            "monitor.alsa.rules" = [
              {
                matches = [ { "node.name" = "~alsa_output.*"; } ];
                actions.update-props."channelmix.max-volume" = 1.5;
              }
            ];
          };
        };

        environment.systemPackages = with pkgs; [
          wireplumber
          alsa-lib
          alsa-utils
          flac
          pulsemixer
        ];
      }
    )
  ];
}
