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
          # Python with RAG dependencies
          (python3.withPackages (
            ps: with ps; [
              sentence-transformers # Embedding generation
              torch # ML framework
              transformers # Hugging Face transformers
              qdrant-client # Vector database client
              python-magic # File type detection
              chardet # Character encoding detection
              numpy # Numerical operations
              requests # HTTP client
            ]
          ))
        ];
        xdg.configFile."opencode/opencode.json" = {
          source = ./opencode/opencode.json;
          force = true;
        };

        xdg.configFile."opencode/dcp.jsonc" = {
          source = ./opencode/dcp.jsonc;
          force = true;
        };

        home.activation.checkOpencodeConfigManaged = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          opencode_config="${config.xdg.configHome}/opencode/opencode.json"
          opencode_dcp="${config.xdg.configHome}/opencode/dcp.jsonc"

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
          check_managed_file "$opencode_dcp"
        '';

        home.activation.cleanupOpencodeLegacyDeps =
          lib.hm.dag.entryAfter [ "checkOpencodeConfigManaged" ]
            ''
              opencode_config_dir="${config.xdg.configHome}/opencode"
              backup_root="${config.xdg.stateHome}/opencode/legacy-config-backup"

              for file in \
                "$opencode_config_dir/node_modules" \
                "$opencode_config_dir/package-lock.json" \
                "$opencode_config_dir/bun.lock"
              do
                if [ ! -e "$file" ]; then
                  continue
                fi

                mkdir -p "$backup_root"
                target="$backup_root/$(basename "$file")"
                if [ -e "$target" ]; then
                  target="$target.$(date +%s)"
                fi

                mv "$file" "$target"
                echo "[home-manager][opencode] moved legacy dependency state: $file -> $target"
              done
            '';
      }
    )
  ];
}
