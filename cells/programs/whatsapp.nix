_: {
  config.my.branches.whatsapp = {
    description = "Local bridge for whatsapp.nvim.";
    needs = [ "desktop" ];

    hmModules = [
      (
        { lib, pkgs, ... }:
        let
          # Keep this revision in sync with lua/plugins/messaging.lua in the Neovim config.
          rev = "741a9e377140cd7c72b9d61a67ad85a4867c930c";
          wa-bridge = pkgs.buildGoModule {
            pname = "wa-bridge";
            version = "unstable-2026-11-17";

            src = pkgs.fetchFromGitHub {
              owner = "dwmkerr";
              repo = "whatsapp.nvim";
              inherit rev;
              hash = "sha256-uSZrwdFPnp4KBJ2MckD1OiOwFGfzMBmW1Q/9rUHazuM=";
            };
            modRoot = "dist/bridge";
            vendorHash = "sha256-8hlpqmefy0hQ8HzpDiTFcweRiYf1ejwtNAJNaHoc6gI=";

            # The bridge uses go-sqlite3.
            env.CGO_ENABLED = 1;
            ldflags = [ "-X main.version=${rev}" ];
            postInstall = ''
              mv "$out/bin/bridge" "$out/bin/wa-bridge"
            '';

            meta = {
              description = "WhatsApp bridge for Neovim";
              homepage = "https://github.com/dwmkerr/whatsapp.nvim";
              license = lib.licenses.mit;
              mainProgram = "wa-bridge";
            };
          };
        in
        {
          # Neovim launches the bridge over stdio; there is no service or listening port.
          # Linking an account stores keys, messages, and media unencrypted in Neovim's data dir.
          programs.neovim.extraPackages = [ wa-bridge ];
        }
      )
    ];
  };
}
