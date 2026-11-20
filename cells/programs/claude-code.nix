{ inputs, ... }:
{
  config.my.branches.desktop.hmModules = [
    (
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        claude = inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default;
        # Declared by shell/claude-gh-token.nix only when the secret exists.
        ghTokenPath = config.sops.secrets.github_token_claude.path or null;
        # Read at launch, so every entry point (terminal, IDE, URL handler)
        # gets the scoped token and the value never enters the Nix store.
        ghTokenArgs = lib.optionalString (ghTokenPath != null) ''
          --run 'f=${ghTokenPath}; if [ -r "$f" ]; then export GH_TOKEN="$(< "$f")"; fi'
        '';
        wrappedClaude = pkgs.symlinkJoin {
          name = "claude-code-with-context-mode";
          paths = [ claude ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram "$out/bin/claude" \
              --prefix CLAUDE_CODE_PLUGIN_DIRS : "${pkgs.context-mode-agent}" \
              ${ghTokenArgs}
          '';
        };
      in
      {
        # Load the store plugin only through this launcher, not via mutable settings.
        home.packages = [ wrappedClaude ];

        # Global Claude Code conventions, applied across every project unless
        # a repository's own CLAUDE.md overrides them.
        home.file.".claude/CLAUDE.md" = {
          source = ./claude/CLAUDE.md;
          force = true;
        };
      }
    )
  ];
}
