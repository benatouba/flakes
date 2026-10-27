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
        jevMcp = config.my.jev.package or null;
        jevRouter = config.my.jev.router or null;
        jevControl = config.my.jev.control or null;
        routerPlugin = pkgs.runCommand "opencode-jev-router" { } ''
          mkdir -p $out
          cp ${./jev-router/opencode-package.json} $out/package.json
          cp ${./jev-router}/controls.mjs ${./jev-router}/decision.mjs ${./jev-router}/router.mjs ${./jev-router}/cache-policy.mjs $out/
          substitute ${./jev-router/opencode.mjs} $out/index.mjs \
            --replace-fail '@router@' '${if jevRouter != null then lib.getExe jevRouter else "disabled"}' \
            --replace-fail '@control@' '${if jevControl != null then lib.getExe jevControl else "disabled"}'
        '';
        wrappedOpencode = pkgs.symlinkJoin {
          name = "opencode-wrapped";
          paths = [ pkgs.opencode ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/opencode \
              --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}" \
              --prefix PATH : "${lib.makeBinPath [ pkgs.bun ]}"
          '';
        };
      in
      {
        home.packages = with pkgs; [
          wrappedOpencode
          bun # runtime for opencode plugin dependency installs
          nil # Nix LSP server
          nodejs_latest # needed for JavaScript tools
        ];

        xdg.configFile."opencode/opencode.jsonc" = {
          # Do not depend on the shared OpenCode service's PATH. The personal
          # branch exposes the wrapper only when its SOPS key is configured.
          source = pkgs.replaceVars ./opencode/opencode.jsonc {
            jevRouterPlugin = lib.optionalString (jevRouter != null) ''
              ${builtins.toJSON (toString routerPlugin)},
            '';
            jevMcpServer = lib.optionalString (jevMcp != null) ''
              "jev": ${
                builtins.toJSON {
                  type = "local";
                  command = [ (lib.getExe jevMcp) ];
                  disabled = false;
                }
              },
            '';
          };
          force = true;
        };

        home.activation.checkOpencodeConfigManaged = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          opencode_config="${config.xdg.configHome}/opencode/opencode.jsonc"

          check_managed_file() {
            file="$1"
            if [ ! -e "$file" ]; then
              echo "[home-manager][opencode] warning: expected managed file missing: $file" >&2
              return
            fi

            if [ ! -L "$file" ]; then
              echo "[home-manager][opencode] warning: file is not a symlink (possible drift): $file" >&2
              return
            fi

            target="$(readlink "$file")"
            case "$target" in
              /nix/store/*) ;;
              *)
                echo "[home-manager][opencode] warning: symlink does not point into /nix/store: $file -> $target" >&2
                ;;
            esac
          }

          check_managed_file "$opencode_config"

          # Remove the retired DCP config, but only if it is still the
          # symlink this module used to manage (never delete user files).
          opencode_dcp="${config.xdg.configHome}/opencode/dcp.jsonc"
          if [ -L "$opencode_dcp" ]; then
            case "$(readlink "$opencode_dcp")" in
              /nix/store/*) rm "$opencode_dcp" ;;
            esac
          fi
        '';
      }
    )
  ];
}
