{ ... }:
{
  config.my.hmModules = [
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
