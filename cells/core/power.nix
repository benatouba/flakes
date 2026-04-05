_: {
  config.my.branches.base.nixosModules = [
    {
      services.tlp = {
        enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "powersave";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
          CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
          CPU_BOOST_ON_AC = 1;
          CPU_BOOST_ON_BAT = 0;

          PLATFORM_PROFILE_ON_AC = "performance";
          PLATFORM_PROFILE_ON_BAT = "low-power";

          START_CHARGE_THRESH_BAT0 = 20;
          STOP_CHARGE_THRESH_BAT0 = 80;

          RUNTIME_PM_ON_AC = "auto";
          RUNTIME_PM_ON_BAT = "auto";

          WIFI_PWR_ON_AC = "off";
          WIFI_PWR_ON_BAT = "on";

          USB_AUTOSUSPEND = 1;
        };
      };

      boot.kernel.sysctl = {
        "vm.swappiness" = 10;
        "vm.vfs_cache_pressure" = 50;
        "net.core.default_qdisc" = "cake";
        "net.ipv4.tcp_congestion_control" = "bbr";
      };

      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = 50;
      };
    }
  ];
}
