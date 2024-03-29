{ config, pkgs, user, inputs, ... }:

{
  imports =
    (import ../../../modules/hardware) ++
    [
      ../hardware-configuration.nix
      ../../../modules/fonts
    ] ++ [
      ../../../modules/desktop/hyprland
    ];

  users.users.root.initialHashedPassword = "$6$4lwj3AGq8M9CQE2.$q8cNPghWHTl/dfE0dMPm2vsh0cMpY2gWxw91/Uadi8jShbvUHJJu3Jg0CvSpqrlEB7a3kvWDf/p2CI3mSqP1c/";
  users.users.${user} = {
    initialHashedPassword = "$6$4lwj3AGq8M9CQE2.$q8cNPghWHTl/dfE0dMPm2vsh0cMpY2gWxw91/Uadi8jShbvUHJJu3Jg0CvSpqrlEB7a3kvWDf/p2CI3mSqP1c/";
    # shell = pkgs.fish;
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" ];
    packages = [
      pkgs.gdal
      pkgs.hugo
      pkgs.gimp
    ];
  };
  boot = {
    supportedFilesystems = [ "ntfs" ];
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
    loader = {
      systemd-boot = {
        enable = false;
        consoleMode = "auto";
      };
      grub = {
	enable = true;
        efiSupport = true;
	# efiInstallAsRemovable = true;
	useOSProber = true;
	devices = [
          "nodev"
	];
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
      # "nvidia-drm.modeset=1"
    ];
    consoleLogLevel = 0;
    initrd.verbose = false;
  };

  programs = {
    dconf.enable = true;
    light.enable = true;
  };

  i18n = {
    supportedLocales = [
      "de_DE.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
    inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [ fcitx5-rime fcitx5-chinese-addons fcitx5-table-extra fcitx5-pinyin-moegirl fcitx5-pinyin-zhwiki ];
    };
  };

  environment = {
    systemPackages = with pkgs; [
      libnotify
      wl-clipboard
      wlr-randr
      wireplumber
      cinnamon.nemo
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
      # tlp
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
