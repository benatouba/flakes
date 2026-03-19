{ config, pkgs, user, inputs, ... }:

{
  imports = [
    ./hardware.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/fonts.nix
    ../../modules/nixos/hardware/bluetooth.nix
    ../../modules/nixos/sops.nix
  ];

  users.users.root.hashedPasswordFile = "/persist/passwords/root";
  users.users.${user} = {
    hashedPasswordFile = "/persist/passwords/${user}";
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "networkmanager" ];
    packages = with pkgs; [ gdal hugo gimp nodejs pnpm ];
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
    ];
    consoleLogLevel = 0;
    initrd.verbose = false;
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

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.policykit.exec" &&
          action.lookup("program") == "${pkgs.tlp}/bin/tlp" &&
          subject.isInGroup("wheel")) {
        return polkit.Result.AUTH_SELF;
      }
    });
  '';
  security.sudo = {
    enable = true;
    extraConfig = ''
      Defaults timestamp_timeout=30
    '';
  };

}
