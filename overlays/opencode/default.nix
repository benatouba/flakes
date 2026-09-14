# opencode 1.18.30 (built with bun 1.4.2) crashes on every prompt with
# "TypeError: undefined is not an object (evaluating 'a.name')" in
# SystemPrompt.environment: core/src/filesystem.ts and
# core/src/filesystem/search.ts import each other and bun's bundler emits
# them in the wrong order, leaving FileSystemSearch.node undefined in the
# layer graph. Upstream: anomalyco/opencode#48876, fix in #48877.
# Drop this overlay once nixpkgs ships a release containing that fix.
_final: prev: {
  opencode = prev.opencode.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./break-filesystem-search-import-cycle.patch ];
  });
}
