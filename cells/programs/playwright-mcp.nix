_: {
  # Playwright MCP for agents; wrapper pins nixpkgs chromium, zero runtime downloads.
  config.my.branches.desktop.hmModules = [
    (
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        # Both nixpkgs wrappers reference the bundled browser set. Replace the
        # test CLI's default as well as MCP's default to remove it from the
        # runtime closure; the outer wrapper always supplies system Chromium.
        browserlessTest = pkgs.playwright-test.overrideAttrs (old: {
          installPhase =
            lib.replaceStrings [ "${pkgs.playwright-driver.browsers}" ] [ "${pkgs.emptyDirectory}" ]
              old.installPhase;
        });
        browserlessMcp = pkgs.playwright-mcp.override {
          playwright-test = browserlessTest;
          playwright-driver = pkgs.playwright-driver // {
            browsers = pkgs.emptyDirectory;
          };
        };
      in
      {
        # Use the system chromium (same as agent-browser) instead of playwright's bundled browsers.
        home.packages = [
          (pkgs.writeShellScriptBin "playwright-mcp" ''
            exec ${browserlessMcp}/bin/playwright-mcp \
              --browser chromium \
              --executable-path ${pkgs.chromium}/bin/chromium "$@"
          '')
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
