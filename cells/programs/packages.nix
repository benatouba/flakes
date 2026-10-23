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
          libreoffice
          nodejs_latest
          obsidian
          ripgrep-all
          zoom-us
        ];

        # Let Nix own pnpm; PNPM_HOME/bin remains available for global tools.
        programs.pnpm.enable = true;
        # pnpm >= 11 otherwise downloads the packageManager version declared by
        # each project. Keep the Nix version, but report compatibility mismatches.
        home.sessionVariables.pnpm_config_pm_on_fail = "warn";
      }
    )
  ];
}
