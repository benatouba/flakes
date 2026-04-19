_: {
  config.my.branches.desktop.hmModules = [
    (
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          opencode
          nil # Nix LSP server
          eslint # JavaScript linter
          prettier # Code formatter
          djlint # Django template linter
          nodejs # needed for JavaScript tools
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
        xdg.configFile."opencode/opencode.json".text = builtins.readFile ./opencode/opencode.json;
      }
    )
  ];
}
