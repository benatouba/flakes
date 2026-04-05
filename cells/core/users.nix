{ config, ... }:
let
  user = config.my.user.name;
in
{
  config.my.branches.base.nixosModules = [
    (
      { pkgs, ... }:
      {
        users.users.root.hashedPasswordFile = "/persist/passwords/root";
        users.users.${user} = {
          hashedPasswordFile = "/persist/passwords/${user}";
          shell = pkgs.zsh;
          isNormalUser = true;
          extraGroups = [
            "wheel"
            "video"
            "audio"
            "networkmanager"
          ];
          packages = with pkgs; [
            gdal
            hugo
            gimp
            nodejs
            pnpm
          ];
        };

      }
    )
  ];
}
