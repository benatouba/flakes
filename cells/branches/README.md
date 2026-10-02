# Branches

The dendritic graph accumulates NixOS and Home Manager modules under
`config.my.branches.<name>.nixosModules` and `config.my.branches.<name>.hmModules`.
Hosts select branches by name instead of importing feature files directly.

- `base`: core system and shell trunk shared by regular machines.
- `desktop`: Wayland, UI, and desktop application modules.
- `security`: host hardening and network security defaults.
- `persist`: impermanence state for system and home directories.
- `secrets`: sops-nix defaults and age key wiring.
- `personal`: private user configuration such as mail, SSH, rbw, and GPG agent.
- `addons`: optional workflow helpers controlled by `my.profile.addons`.
- `server`: headless server defaults.
- `dns`: Pi-hole + Unbound DNS stack (`my.dns.enable`, default true when selected).
- `ddns`: deSEC dynamic DNS updater (`my.ddns.enable`, default true when selected; needs `secrets`).
- `finance`: Beancount ledger automation, Fava UI, and Paperless-oriented finance ingestion.
- `vpn`: NordVPN client services.
- `paperless`: Paperless-ngx document management, PDF tools, sync, and local backup services.
- `matrix`: Matrix homeserver services and bridges.
- `wger`: Wger workout manager stack (PostgreSQL, Redis, web, nginx, celery, backups).

A branch may declare `needs = [ "other" ]`; host resolution throws when a
selected branch's needs are not also selected. Needs are not transitive and are
not auto-selected. Description-only branches live in `catalog.nix`.

Use `my.hosts.<name>.includeProfileBranches = false` for minimal hosts that should
only use their explicitly listed branches.
