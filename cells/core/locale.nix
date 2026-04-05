_: {
  config.my.branches.base.nixosModules = [
    {
      time.timeZone = "Europe/Berlin";
      i18n.defaultLocale = "en_US.UTF-8";
      i18n.supportedLocales = [
        "de_DE.UTF-8/UTF-8"
        "en_US.UTF-8/UTF-8"
      ];
    }
  ];
}
