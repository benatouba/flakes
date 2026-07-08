_: {
  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          bitwarden-desktop
          commitmsgfmt
          devenv
          gdal
          gimp
          hugo
          libreoffice-fresh
          nodejs_latest
          obsidian
          pnpm
          ripgrep-all
          zoom-us
        ];
      }
    )
  ];
}
