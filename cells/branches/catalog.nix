# Trunk branches that only carry a description. Their modules are attached
# from elsewhere via `config.my.branches.<name>.nixosModules/hmModules`.
_: {
  config.my.branches = {
    base.description = "Dendritic base branch for core and shell trunk modules.";
    security.description = "Dendritic security branch for host hardening modules.";
    persist.description = "Dendritic persistence branch for impermanence state.";
    secrets.description = "Dendritic secrets branch for sops-nix integration.";
    personal.description = "Dendritic personal branch for user-private applications and accounts.";
  };
}
