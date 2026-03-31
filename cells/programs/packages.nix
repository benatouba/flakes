{ ... }:
{
  config.my.hmModules = [
    (
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          bitwarden-desktop
          commitmsgfmt
          claude-code-bin
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
