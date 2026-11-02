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
          # Spell-check dictionaries; the LibreOffice wrapper picks them up from
          # share/hunspell in the profile via DICPATH.
          hunspellDicts.de_DE
          hunspellDicts.en_GB-ize # Oxford spelling (-ize)
          hunspellDicts.en_US
          hunspellDicts.es_ANY
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
