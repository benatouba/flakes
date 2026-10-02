_: {
  # Token-efficient browser CLI for agents; full guide via `agent-browser skills get core`.
  # CLI + shared skill is primary; MCP (core,debug) optional per session.
  config.my.branches.desktop.hmModules = [
    (
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        home.packages = with pkgs; [
          agent-browser
          chromium
        ];

        # Pinned NixOS chromium (no network download); --no-sandbox is headless agent-only.
        # Targets are local dev frontends, not untrusted browsing.
        home.file.".agent-browser/config.json".text = builtins.toJSON {
          executablePath = "${pkgs.chromium}/bin/chromium";
          args = "--no-sandbox,--disable-gpu,--disable-dev-shm-usage";
        };

        # One link serves Claude Code and OpenCode (Claude-compat path).
        # Do NOT also link under ~/.config/opencode/skills (dupes).
        home.file.".claude/skills/agent-browser" = {
          source = "${pkgs.agent-browser}/skills/agent-browser";
          force = true;
        };

        # ~/.claude.json is CLI-owned; register idempotently via `claude mcp add`.
        # Activation PATH lacks the user profile, so prefix it or registration never fires.
        home.activation.registerAgentBrowserClaudeMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          export PATH="/etc/profiles/per-user/${config.home.username}/bin:$PATH"
          if command -v claude >/dev/null 2>&1; then
            if ! claude mcp list 2>/dev/null | grep -qE '(^|[^a-zA-Z0-9_-])agent-browser([^a-zA-Z0-9_-]|$)'; then
              claude mcp add agent-browser --scope user -- agent-browser mcp --tools core,debug >/dev/null 2>&1 || true
            fi
          fi
        '';

        # Guard against drift like the opencode module does: config must stay
        # a nix-store symlink, skill must stay a directory symlink.
        home.activation.checkAgentBrowserManaged = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          ab_config="${config.home.homeDirectory}/.agent-browser/config.json"
          ab_skill="${config.home.homeDirectory}/.claude/skills/agent-browser"
          if [ -e "$ab_config" ] && [ ! -L "$ab_config" ]; then
            echo "[home-manager][agent-browser] warning: $ab_config is not a symlink (possible drift)" >&2
          fi
          if [ -e "$ab_skill" ] && [ ! -L "$ab_skill" ]; then
            echo "[home-manager][agent-browser] warning: $ab_skill is not a symlink (possible drift)" >&2
          fi
        '';
      }
    )
  ];
}
