{
  inputs,
  lib,
  ...
}:
let
  secretsRoot = toString inputs.nix-secrets;
  defaultSopsFile = "${secretsRoot}/secrets.yaml";
  secretName = "github_token_claude";

  # sops keys stay plaintext; guard so a missing token warns instead of failing.
  hasToken =
    builtins.pathExists defaultSopsFile
    && lib.hasInfix "${secretName}:" (builtins.readFile defaultSopsFile);
in
{
  # Declares the fine-grained GitHub token for Claude Code. The claude wrapper
  # in programs/claude-code.nix exports it as GH_TOKEN, so only Claude Code
  # sessions use it; interactive shells keep the keyring login.
  config.my.branches.personal.hmModules = [
    (
      { lib, ... }:
      {
        warnings = lib.optional (!hasToken) ''
          Claude Code: `${secretName}` is missing from ${defaultSopsFile}, so
          GH_TOKEN will not be set for Claude Code. Add it with:
            sops ~/.local/secrets/secrets.yaml   # ${secretName}: github_pat_...
            just update-secrets
        '';
      }
      // lib.optionalAttrs hasToken {
        sops.secrets.${secretName} = { };
      }
    )
  ];
}
