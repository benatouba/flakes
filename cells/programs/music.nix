_: {
  config.my.branches.desktop.hmModules = [
    (
      {
        config,
        pkgs,
        ...
      }:
      {
        home = {
          packages = with pkgs; [
            cava
            mpc
            pear-desktop
            netease-cloud-music-gtk
            go-musicfox
            supercollider-with-sc3-plugins
            sonic-pi

            haskell-language-server
            haskellPackages.tidal
            (haskellPackages.ghcWithPackages (p: [ p.tidal ]))
          ];
          sessionVariables = {
            TIDAL_BOOT = "${config.home.homeDirectory}/.config/tidal/BootTidal.hs";
            TIDAL_SAMPLE_DIR = "${pkgs.sonic-pi}/etc/samples";
            SONIC_PI_SERVER_DIR = "${pkgs.sonic-pi}/app/server";
          };
        };
        programs = {
          ncmpcpp = {
            enable = true;
            mpdMusicDir = null;
          };
        };
        home.file = {
          ".config/ncmpcpp/config".text = ''
            mpd_music_dir = ~/Music
          '';
          ".config/tidal/BootTidal.hs".text = ''
            :set -XOverloadedStrings
            :set prompt ""

            import Sound.Tidal.Context

            let target = superdirtTarget {oLatency = 0.1, oAddress = "127.0.0.1", oPort = 57120}
                conf = defaultConfig {cFrameTimespan = 1 / 20}

            tidal <- startTidal target conf

            let p = streamReplace tidal
                hush = streamHush tidal
                list = streamList tidal
                mute = streamMute tidal
                unmute = streamUnmute tidal
                solo = streamSolo tidal
                unsolo = streamUnsolo tidal
                once = streamOnce tidal
                asap = once
                nudgeAll = streamNudgeAll tidal
                all = streamAll tidal
                resetCycles = streamResetCycles tidal
                setcps = asap . cps
                d1 = p 1
                d2 = p 2
                d3 = p 3
                d4 = p 4
                d5 = p 5
                d6 = p 6
                d7 = p 7
                d8 = p 8

            :set prompt "tidal> "
          '';
        };

        services = {
          mpd = {
            enable = true;
            musicDirectory = "~/Music";
            extraConfig = ''
              audio_output {
                      type            "pipewire"
                      name            "PipeWire Sound Server"
              }
            '';
          };
        };
      }
    )
  ];
}
