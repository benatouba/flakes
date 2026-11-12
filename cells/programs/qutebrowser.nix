_: {
  config.my.branches.desktop.hmModules = [
    (
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        # Generated EasyList distribution, pinned independently of flake.lock.
        # Keep both lists together when updating; see qutebrowser/README.md.
        listRevision = "c74e690afe1ba677ebf34f7d28ed35ff219a2d85";
        easylist = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/easylist/easylist/${listRevision}/easylist.txt";
          hash = "sha256-A5nBSh4i1yMXgYP8CdnSvLFTvOqqPvv0UUVXAh7EOJ4=";
        };
        easyprivacy = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/easylist/easylist/${listRevision}/easyprivacy.txt";
          hash = "sha256-8K3UM8aSChFo9Nzd07hWoVcyMZ3ywS8M1+i1qExYKKY=";
        };
        adblockPython = pkgs.python3.withPackages (ps: [ ps.adblock ]);
        # qutebrowser otherwise starts with an empty engine until :adblock-update.
        # The Nix-owned cache is deliberately read-only; update pins, not at runtime.
        adblockCache =
          pkgs.runCommand "qutebrowser-adblock-cache"
            {
              nativeBuildInputs = [ adblockPython ];
            }
            ''
              python - ${easylist} ${easyprivacy} "$out" <<'PY'
              import pathlib
              import sys
              import adblock

              filters = adblock.FilterSet()
              for filename in sys.argv[1:-1]:
                  filters.add_filter_list(pathlib.Path(filename).read_text())
              engine = adblock.Engine(filters)
              engine.serialize_to_file(sys.argv[-1])
              PY
            '';
        sponsorblockSource = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/mchangrh/sb.js/61389844ffdba6c66ed4dc7b8edd728e771c67a6/docs/sb.user.js";
          hash = "sha256-nrQ4Fz8g4Odi9aa+tZB8gefF5w1xCCw/Ryg90Q4kJmM=";
        };
        # LGPL-3.0-or-later; built script, NOT the mutable CDN loader.
        # Limit to sponsor skipping, disable skip telemetry, and also inject on
        # YouTube's homepage so SPA navigation from there can start the script.
        sponsorblock = pkgs.runCommand "sponsorblock.user.js" { } ''
          substitute ${sponsorblockSource} "$out" \
            --replace-fail 'const skipTracking = true' 'const skipTracking = false' \
            --replace-fail 'const categories = [' 'const unusedCategories = [' \
            --replace-fail 'const actionTypes = ["skip", "mute", "full", "poi"]' 'const categories = ["sponsor"]; const actionTypes = ["skip"]' \
            --replace-fail 'https://www.youtube.com/watch*' 'https://www.youtube.com/*' \
            --replace-fail 'if (videoID === getVideoID()) return' 'if (!getVideoID() || videoID === getVideoID()) return'
        '';
        passwordPicker = pkgs.rofi-rbw.override { waylandSupport = true; };
      in
      {
        programs.qutebrowser = {
          enable = true;
          package = pkgs.qutebrowser; # Already includes Python adblock / Brave's Rust engine.
          # Retain explicit per-site permissions; managed defaults below win.
          loadAutoconfig = true;
          settings = {
            backend = "webengine";
            url.default_page = "about:blank";
            url.start_pages = [ "about:blank" ];
            auto_save.session = false;
            colors.webpage = {
              preferred_color_scheme = "dark";
              darkmode.enabled = true;
              darkmode.policy.images = "never";
            };
            content = {
              blocking = {
                enabled = true;
                method = "adblock"; # Fail visibly if the Rust dependency goes missing.
                adblock.lists = [
                  "file://${easylist}"
                  "file://${easyprivacy}"
                ];
                hosts.lists = [ ]; # No fallback network downloads.
              };
              cookies.accept = "no-3rdparty";
              dns_prefetch = false;
              hyperlink_auditing = false;
              autoplay = false;
              geolocation = false;
              notifications.enabled = false;
              webrtc_ip_handling_policy = "default-public-interface-only";
            };
          };
          greasemonkey = [
            sponsorblock
            (pkgs.writeText "youtube-focus.user.js" (builtins.readFile ./qutebrowser/youtube-focus.user.js))
          ];
          keyBindings.normal = {
            ",b" = "spawn --detach ${lib.getExe pkgs.brave} {url}";
            ",d" = "config-cycle -t colors.webpage.darkmode.enabled";
            ",a" = "config-cycle -p -t -u *://{url:host}/* content.blocking.enabled";
            ",f" = "jseval --quiet document.documentElement.classList.toggle('qute-focus')";
          }
          // lib.optionalAttrs config.programs.rbw.enable {
            # Manual picker/OS typing, never passwords through qutebrowser's FIFO.
            ",p" = "spawn --detach ${lib.getExe passwordPicker} --no-help --clear-after 20";
          };
        };

        xdg.dataFile."qutebrowser/adblock-cache.dat".source = adblockCache;
      }
    )
  ];
}
