_: {
  # Token-efficient browser for AI agents (Claude Code, OpenCode).
  #
  # Why agent-browser: classic Chrome MCP servers burn ~13-18k tokens on tool
  # schemas alone and re-dump full accessibility trees after every action
  # (~50-114k tokens per 10-step flow). agent-browser instead exposes a CLI
  # with compact `@eN` snapshot refs (~200-400 tokens per snapshot, ~7k per
  # 10-step flow). Agents drive it via Bash, so zero MCP schema overhead.
  # The bundled skill stub below teaches that workflow; the full versioned
  # guide is served by the CLI itself (`agent-browser skills get core`).
  #
  # This module provides both layers, CLI-first:
  # - CLI + skill (primary): `agent-browser` + pinned headless `chromium`
  #   plus a shared skill at ~/.claude/skills/agent-browser, which OpenCode
  #   also reads via its Claude-compat path. No per-session token cost.
  # - MCP (optional): `agent-browser mcp --tools core,debug` registered in
  #   opencode.jsonc and in Claude Code user scope. `core` covers
  #   navigate/snapshot/interact/screenshot/eval; `debug` adds
  #   console/errors/tracing/a11y audit for investigating broken frontends.
  #   Enable per session, disable when not needed.
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

        # Point the agent browser at pinned NixOS chromium instead of letting
        # it download Chrome from the network (impure, breaks sandbox).
        # `--no-sandbox` is scoped to this headless agent browser only; the
        # interactive Brave session is unaffected. Agent targets are local
        # dev frontends, not untrusted browsing.
        home.file.".agent-browser/config.json".text = builtins.toJSON {
          executablePath = "${pkgs.chromium}/bin/chromium";
          args = "--no-sandbox,--disable-gpu,--disable-dev-shm-usage";
        };

        # Shared skill: Claude Code reads ~/.claude/skills, OpenCode reads
        # the same path via its Claude-compat lookup, so one link serves
        # both. Do NOT also link it under ~/.config/opencode/skills (dupes).
        home.file.".claude/skills/agent-browser" = {
          source = "${pkgs.agent-browser}/skills/agent-browser";
          force = true;
        };

        # Claude Code user-scope MCP lives in ~/.claude.json, which is
        # CLI-owned state and must not be overwritten declaratively, so
        # register idempotently via the supported `claude mcp add` path.
        home.activation.registerAgentBrowserClaudeMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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
