{ config, pkgs, user, inputs, ... }:

{
  imports = (import ../../../modules/hardware)
    ++ [ ../hardware-configuration.nix ../../../modules/fonts ]
    ++ [ ../../../modules/desktop/hyprland ];

  users.users.root.hashedPasswordFile = "/persist/passwords/root";
  users.users.${user} = {
    hashedPasswordFile = "/persist/passwords/${user}";
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "networkmanager" ];
    packages = [ pkgs.gdal pkgs.hugo pkgs.gimp ];
  };
  boot = {
    supportedFilesystems = [ "btrfs" ];
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        useOSProber = false;
        configurationLimit = 10;
        # Use mirroredBoots with path = efiSysMountPoint to work around NixOS regression
        # where the default mirroredBoots uses path = "/boot" (tmpfs on impermanence setups)
        mirroredBoots = [
          {
            path = "/boot/efi";
            efiSysMountPoint = "/boot/efi";
            devices = [ "nodev" ];
          }
        ];
      };
      efi = {
        canTouchEfiVariables = false;
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
      # flameshot
      grim
      brightnessctl
      playerctl
      cliphist
      rofi-rbw
      hyprshot
      hyprpaper
      hypridle
      wlsunset
      waypaper
      jq
      wlogout
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
