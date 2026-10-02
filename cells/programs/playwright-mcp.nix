_: {
  # Playwright MCP for agents; nixpkgs wrapper pins browsers, zero runtime downloads.
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
          playwright-mcp
        ];

        # ~/.claude.json is CLI-owned; register idempotently via `claude mcp add`.
        # Activation PATH lacks the user profile, so prefix it or lookup fails.
        home.activation.registerPlaywrightClaudeMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          export PATH="/etc/profiles/per-user/${config.home.username}/bin:$PATH"
          if command -v claude >/dev/null 2>&1 && command -v playwright-mcp >/dev/null 2>&1; then
            if ! claude mcp list 2>/dev/null | grep -qE '(^|[^a-zA-Z0-9_-])playwright([^a-zA-Z0-9_-]|$)'; then
              claude mcp add playwright --scope user -- playwright-mcp >/dev/null 2>&1 || true
            fi
          fi
        '';
      }
    )
  ];
}
