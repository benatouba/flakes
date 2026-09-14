_: {
  config.my.branches.desktop.nixosModules = [
    {
      # logind's default for the power button is an immediate poweroff.  On a
      # desktop session a tap should behave like closing the lid: suspend,
      # which hypridle turns into lock-then-sleep.  Holding the button still
      # hard-powers-off through the firmware regardless of this setting.
      services.logind.settings.Login.HandlePowerKey = "suspend";
    }
  ];
}
