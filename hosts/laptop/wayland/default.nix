{ config, pkgs, user, inputs, ... }:

let
  pw_hash =
    "$6$JLIrmQOf4ku.qNkw$qpdNHeLlbeQeRGyJl8uKZBNXryYsOCtd2xB/8IFOwCRPtUGcIaIso9RMQtZ7bQF5R1lm5ig4CByla0ImKp2XH/";
in {
  imports = (import ../../../modules/hardware)
    ++ [ ../hardware-configuration.nix ../../../modules/fonts ]
    ++ [ ../../../modules/desktop/hyprland ];

  users.users.root.initialHashedPassword = pw_hash;
  users.users.${user} = {
    initialHashedPassword = pw_hash;
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "networkmanager" ];
    packages = [ pkgs.gdal pkgs.hugo pkgs.gimp ];
  };
  boot = {
    supportedFilesystems = [ "btrfs" ];
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
    loader = {
      systemd-boot = {
        enable = false;
        consoleMode = "auto";
      };
      grub = {
        enable = true;
        efiSupport = true;
        useOSProber = true;
        devices = [ "nodev" ];
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
      timeout = 3;
    };
    kernelParams = [
      "quiet"
      "splash"
      "amd_pstate=active"
    ];
    consoleLogLevel = 0;
    initrd.verbose = false;
  };

  programs = {
    dconf.enable = true;
    light.enable = true;
  };

  i18n = { supportedLocales = [ "de_DE.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ]; };

  environment = {
    systemPackages = with pkgs; [
      libnotify
      wl-clipboard
      wireplumber
      nemo
      networkmanagerapplet
      wev
      wf-recorder
      alsa-lib
      alsa-utils
      flac
      pulsemixer
      imagemagick
      pkgs.sway-contrib.grimshot
      flameshot
      grim
    ];
  };

  services = {
    dbus.packages = [ pkgs.gcr ];
    getty.autologinUser = "${user}";
    gvfs.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };

  security.polkit.enable = true;
  security.sudo = {
    enable = true;
    extraConfig = ''
      ${user} ALL=(ALL) NOPASSWD:ALL
    '';
  };
  security.doas = {
    enable = false;
    extraConfig = ''
      permit nopass :wheel
    '';
  };

}
