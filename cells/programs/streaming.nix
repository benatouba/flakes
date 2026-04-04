{ ... }:
{
  config.my.nixosModules = [({ config, pkgs, ... }: {
    # Virtual camera (v4l2loopback)
    boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
    boot.kernelModules = [ "v4l2loopback" ];
    boot.extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=10 card_label="OBS Virtual Camera" exclusive_caps=1
    '';

    environment.systemPackages = with pkgs; [
      v4l-utils
    ];
  })];

  config.my.hmModules = [({ pkgs, ... }: {
    # OBS Studio with streaming plugins
    programs.obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs                    # Wayland screen/window capture (wlroots)
        obs-pipewire-audio-capture # Per-app audio capture via PipeWire
        obs-multi-rtmp            # Simultaneous streaming to Twitch + YouTube
        obs-backgroundremoval     # Webcam background removal
        obs-move-transition       # Smooth source animations
        obs-source-record         # Record individual sources while streaming
        obs-vaapi                 # Hardware-accelerated encoding (AMD VCN)
      ];
    };

    home.file.".config/obs-studio/themes".source = ./obs-studio/themes;

    home.packages = with pkgs; [
      chatterino2
    ];

    # Hyprland window rules for streaming
    wayland.windowManager.hyprland.extraConfig = ''
      # Streaming rules
      windowrule {
          name = obs-opaque
          match:class = ^(com\.obsproject\.Studio)$
          opaque = true
      }

      windowrule {
          name = obs-idle-inhibit
          match:class = ^(com\.obsproject\.Studio)$
          idle_inhibit = always
      }

      windowrule {
          name = chatterino-float
          match:class = ^(com\.chatterino\.)$
          float = true
          size = 400 700
          move = 100%-w-10 60
      }

      # Streaming workspace
      workspace = name:stream, monitor:eDP-1, on-created-empty:obs

      # Streaming workspace keybinds
      bind = SUPER_L, s, workspace, name:stream
      bind = SUPER_L SHIFT, s, movetoworkspace, name:stream
    '';
  })];
}
