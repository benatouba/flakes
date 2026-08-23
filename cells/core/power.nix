_: {
  config.my.branches.base.nixosModules = [
    {
      services.power-profiles-daemon.enable = false;

      services.tlp = {
        enable = true;
        settings = {
          TLP_AUTO_SWITCH = 1;

          CPU_DRIVER_OPMODE_ON_AC = "active";
          CPU_DRIVER_OPMODE_ON_BAT = "active";

          CPU_SCALING_GOVERNOR_ON_AC = "powersave";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
          CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
          CPU_BOOST_ON_AC = 1;
          CPU_BOOST_ON_BAT = 0;

          PLATFORM_PROFILE_ON_AC = "performance";
          PLATFORM_PROFILE_ON_BAT = "low-power";

          PCIE_ASPM_ON_AC = "default";
          # Let the kernel drive PCIe links into L1/L1SS on battery instead of
          # leaving the policy to firmware.  Worth ~0.5-1 W across the NVMe,
          # wifi and USB controllers.
          PCIE_ASPM_ON_BAT = "powersupersave";

          RUNTIME_PM_ON_AC = "on";
          RUNTIME_PM_ON_BAT = "auto";
          AHCI_RUNTIME_PM_ON_AC = "on";
          AHCI_RUNTIME_PM_ON_BAT = "auto";

          # Pack wakeups onto fewer cores/dies so the rest can reach deeper
          # package C-states.
          SCHED_POWERSAVE_ON_BAT = 1;

          WIFI_PWR_ON_AC = "off";
          # rtw89 (RTL8852AE) power save.  Historically buggy on kernels
          # 5.16-6.1; re-enabled on battery for 7.x.  If wifi starts dropping
          # or stalling on battery, set this back to "off" first.
          WIFI_PWR_ON_BAT = "on";
          WOL_DISABLE = "Y";

          USB_AUTOSUSPEND = 1;
          USB_EXCLUDE_BTUSB = 1;
          NMI_WATCHDOG = 0;

          START_CHARGE_THRESH_BAT0 = 20;
          STOP_CHARGE_THRESH_BAT0 = 80;
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
