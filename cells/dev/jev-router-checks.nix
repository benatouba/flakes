_: {
  perSystem =
    { pkgs, ... }:
    {
      checks.jev-router =
        pkgs.runCommand "jev-router-tests" { nativeBuildInputs = [ pkgs.nodejs_latest ]; }
          ''
            cp -r ${../programs/jev-router} router
            node --test router/*.test.mjs
            touch $out
          '';
    };
}
