# Host configuration guidance

These instructions apply to NixOS host definitions and host-specific modules. Follow the repository-root `CLAUDE.md` in addition to these rules.

## Host-change workflow

Before modifying a host:

- Identify the exact flake output, hostname, system architecture, deployment path, boot method, and physical/virtual role of the target host.
- Inspect its imports, shared modules, hardware configuration, Home Manager integration, secrets, networking, storage, and service definitions.
- Keep host-specific configuration in this directory or the repository’s established host-specific location. Move genuinely reusable logic into a shared module only after confirming that it is common and parameterised safely.
- Do not copy another host’s hardware, disk, network-interface, filesystem, user, secret, or service assumptions without verifying they apply.

## Networking and remote access

- Default to a deny-by-default exposure model. Open only required firewall ports and document the service, protocol, interface/exposure scope, and purpose near the change.
- Bind services to loopback/private interfaces where public exposure is not required. Do not expose admin, database, metrics, development, or internal service ports publicly by default.
- For reverse proxies, define explicit virtual hosts, TLS behavior, upstreams, request limits, and trusted-proxy boundaries. Do not trust forwarded client headers from arbitrary sources.
- Treat DNS, domain names, IP addresses, WireGuard peers, VPN routes, SSH endpoints, and firewall rules as security-sensitive configuration. Validate the intended host and blast radius before changing them.
- Keep OpenSSH conservative: avoid password login and root login where feasible, use explicitly authorized keys, restrict forwarding/features when not required, and consider rate limiting or network restrictions for Internet-exposed access.
- Do not disable the firewall, broad-open ports, use `0.0.0.0/0` access controls, or accept arbitrary forwarded headers merely to make a service work. Escalate instead.

## Users, privileges, and secrets

- Use dedicated system users/groups for services. Do not run services as root unless required and justified.
- Grant users, services, and groups only the permissions, sudo access, device access, socket access, and filesystem access they need.
- Keep secrets encrypted and out of the Nix store. Use only the approved repository secrets workflow.
- Set explicit file ownership and restrictive permissions for credentials, private keys, service data, backups, and runtime state.
- Do not define user passwords, plain-text credentials, or private key material in Nix expressions.

## Storage, boot, and resilience

- Treat disks, filesystems, LUKS, ZFS/Btrfs/LVM, swap, bootloaders, kernels, initrd configuration, and mount options as high-risk changes.
- Confirm device identity and data-loss risk before suggesting or making storage-related changes. Do not use destructive disk commands, reformatting, repartitioning, or destructive filesystem operations without explicit user confirmation.
- Preserve bootability and remote recovery. For boot/kernel/encryption/network changes, identify a tested rollback or physical-console recovery path.
- Define persistent state intentionally. For stateful services, identify data directory, ownership, backup/restore procedure, retention, disk-growth expectations, and upgrade/migration behavior.
- Keep backup credentials, targets, encryption keys, and restore tests protected. A backup configuration is incomplete without a plausible restore path.

## Service hardening

- Prefer upstream NixOS service modules. For custom services, use explicit `systemd` units, dedicated users, predictable state/runtime/cache/log directories, restart behavior, resource limits, and clear dependencies.
- Harden services proportionately using `systemd` sandboxing and isolation options compatible with the service: for example filesystem restrictions, privilege restrictions, capability bounding, namespace isolation, and network restrictions.
- Validate hardening against actual service needs; do not blindly enable settings that break persistence, sockets, DNS, certificate renewal, or required device/network access.
- Use `systemd-analyze security <unit>` as one input to review custom or Internet-exposed services, then make targeted improvements rather than optimizing only a numeric score.
- Configure TLS for Internet-facing services. Manage certificates and private-key permissions carefully; do not terminate TLS insecurely without an explicit architecture decision.
- Apply request, connection, resource, and timeout limits appropriate to exposed services. Do not expose dashboards, metrics, admin UIs, databases, or debug endpoints without authentication and explicit access control.

## Host validation

Before declaring a host change complete, use the narrowest safe checks that cover it:

- Format/check the affected Nix files according to repository conventions.
- Evaluate or build the exact named host configuration.
- For network/service changes, inspect the resulting firewall, listening interfaces, systemd unit configuration, users, filesystem permissions, and dependency graph as relevant.
- For changes that might affect remote access, boot, storage, or networking, state the rollback/recovery plan before activation.
