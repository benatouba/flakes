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
          sleev # context-management gateway (replaces opencode-dcp plugin)
        ];

        # Sleev's downloaded onefile gateway cannot run on NixOS. Both this
        # unit and the CLI use the pinned gateway's FHS wrapper instead.
        # Account/credential configuration is created interactively by `sleev
        # setup`, never placed in the store. Provider routes live in the managed
        # OpenCode config; credentials remain in OpenCode's own auth storage.
        systemd.user.services.sleeve-gateway = {
          Unit = {
            Description = "Sleev local context-management gateway";
            ConditionPathExists = "${config.xdg.configHome}/sleev/config.json";
          };
          Service = {
            ExecStart = "${lib.getExe pkgs.sleev-gateway} --host 127.0.0.1 --port 17321 --config ${config.xdg.configHome}/sleev/config.json --cli-version ${pkgs.sleev.version}";
            Restart = "on-failure";
            RestartSec = 5;
            UMask = "0077";
          };
          Install.WantedBy = [ "default.target" ];
        };

        # Routing is declarative: edit this baseline rather than using
        # `sleev harness opencode enable/disable` to mutate local overrides.
        xdg.configFile."opencode/opencode.jsonc" = {
          source = ./opencode/opencode.jsonc;
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

          # The four managed provider routes require the gateway above.
          if ! (exec 3<>/dev/tcp/127.0.0.1/17321) 2>/dev/null; then
            echo "[home-manager][opencode] warning: sleev gateway not reachable at 127.0.0.1:17321" >&2
            echo "[home-manager][opencode] warning: run 'sleev setup' if needed, then check 'systemctl --user status sleeve-gateway'" >&2
          else
            exec 3<&- 3>&-
          fi
        '';
      }
    )
  ];
}
