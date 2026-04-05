_: {
  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          bitwarden-desktop
          commitmsgfmt
          devenv
          libreoffice-fresh
          obsidian
          ripgrep-all
          zoom-us
        ];
      }
    )
  ];
}
