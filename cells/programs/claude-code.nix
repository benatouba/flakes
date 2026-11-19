{ inputs, ... }:
{
  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      let
        claude = inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default;
        wrappedClaude = pkgs.symlinkJoin {
          name = "claude-code-with-context-mode";
          paths = [ claude ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram "$out/bin/claude" \
              --prefix CLAUDE_CODE_PLUGIN_DIRS : "${pkgs.context-mode-agent}"
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
