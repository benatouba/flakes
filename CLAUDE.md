# NixOS flake repository guidance

## Repository purpose and scope

This repository declaratively manages NixOS hosts and may also manage Home Manager profiles, packages, development shells, deployment configuration, and self-hosted services.

Treat configuration changes as infrastructure changes. Prefer explicit, reproducible, reviewable, least-privilege configuration over imperative, machine-local changes.

## Skill and context routing

Before planning, editing, reviewing, or debugging:

- Inspect the repository structure, `flake.nix`, `flake.lock`, and the relevant host, module, Home Manager, package, service, or secrets configuration before changing anything.
- For a change affecting a particular host, inspect that host’s configuration and all imported modules first.
- For a change affecting a user environment, inspect the applicable Home Manager configuration and its imports first.
- For a new service, port, user, package, secret, input, overlay, deployment mechanism, or hardware-specific setting, identify its scope: shared module, host-specific module, user profile, or development environment.
- Do not apply generic NixOS snippets without adapting them to existing naming, module boundaries, input pinning, security model, and operational conventions.

## General engineering standards

Apply these rules automatically to every plan, code change, review, test, and configuration change.

- Write idiomatic, readable Nix. Keep modules cohesive, use clear option names, and avoid unnecessary abstraction, duplication, and hidden evaluation magic.
- Prefer declarative NixOS and Home Manager options over imperative shell commands, mutable manual steps, or post-activation mutations.
- Keep changes scoped. Do not perform unrelated refactors, broad package upgrades, flake-input updates, or formatting-only churn while implementing a focused task.
- Preserve reproducibility: commit and maintain `flake.lock` when flake inputs change. Do not use unpinned remote sources, mutable branch assumptions, or ad-hoc downloads in activation scripts.
- Follow existing repository conventions for module layout, formatter, linting, evaluation, testing, CI, secrets, deployment, host naming, and platform support.
- Prefer upstream NixOS/Nixpkgs/Home Manager modules and options over custom systemd units or handwritten scripts when upstream support meets the requirement.
- Do not add a package, flake input, overlay, binary cache, substituter, service, or external integration unless it is necessary, maintained, license-compatible, and its supply-chain, security, privacy, and operational impact has been considered.
- Document non-obvious decisions, required manual recovery steps, externally reachable services, secret dependencies, and host-specific constraints near the relevant module or in repository documentation.

## Validation and safe operations

- Select checks appropriate to the scope before declaring work complete: formatting, static checks, flake evaluation, host build, Home Manager build, tests, and relevant service checks.
- Prefer a build/evaluation before an activation. Do not claim a configuration works merely because the Nix syntax appears valid.
- Do not run or recommend `nixos-rebuild switch`, remote deployment, reboot, destructive cleanup, rollback-pruning, disk operations, credential rotation, or service activation without the user’s explicit intent and an appropriate recovery/rollback consideration.
- State the exact host/configuration target for build or activation commands. Avoid commands that accidentally target the current machine when a named flake target is intended.
- For changes with boot, networking, storage, remote access, display-manager, kernel, or firewall impact, identify a rollback path before activation.
- Consider evaluation purity, supported systems, and cross-platform implications when changing flake outputs.

## Shared security baseline

Apply least privilege, secure defaults, defense in depth, and minimal exposed surface area.

- Do not place passwords, private keys, tokens, API keys, recovery codes, age identities, or decrypted secret values in Git, Nix source, derivation inputs, store paths, logs, shell history, service environment listings, or world-readable files.
- Use the repository’s approved secret-management approach. Do not invent a new secrets workflow or silently replace the existing one.
- Use stable identities and explicit ownership/permissions for service users, state directories, runtime directories, credentials, and persistent data.
- Run network services as dedicated non-root users unless a service genuinely requires elevated privileges. Grant only the filesystem paths, capabilities, devices, and network access that are needed.
- Do not weaken authentication, SSH policy, firewall policy, encryption, service isolation, update policy, logging protections, or privacy defaults without explicitly flagging the impact and receiving a decision.
- Do not log secrets or unnecessary personal data. Ensure diagnostic settings do not expose credentials, tokens, private configuration, or sensitive user data.
- Keep package sources and binary substitutes trusted, explicit, and minimal. Flag any new cache, substituter, signing key, remote builder, or externally fetched executable for review.

## Privacy and EU data protection

This is an engineering baseline, not legal advice. Flag decisions requiring product, security, or data-protection input rather than inventing compliance conclusions.

- Apply data minimisation to system logs, monitoring, analytics, backups, metrics, alerting, user accounts, service configuration, and external integrations.
- Before enabling a service that processes personal data, identify the data categories, purpose, storage location, access model, external recipients/processors, retention/deletion approach, backup implications, and any cross-border transfer.
- Make privacy-protective defaults: minimal telemetry, no optional tracking by default, least-privilege access, restrictive sharing, and no public exposure unless required and reviewed.
- Do not invent a lawful basis, consent wording, retention period, controller/processor role, data-transfer safeguard, or DPIA conclusion. Flag missing decisions.
- Prefer synthetic, anonymised, or pseudonymised data in development, examples, fixtures, demos, and tests. Do not commit production data or operational dumps.

## Required escalation

Pause and clearly flag the issue before implementing if a request would:

- expose a new network service, open a firewall port, add a reverse proxy/vhost, enable remote access, alter DNS, or change authentication;
- add a third-party processor, analytics/telemetry service, hosted AI service, remote build cache, binary substituter, remote builder, monitoring endpoint, or cross-border data transfer;
- store or process credentials, tokens, health, biometric, financial, location, or other sensitive personal data;
- alter boot, kernel, storage, encryption, networking, firewall, SSH, user access, secrets, backups, retention, or rollback behavior;
- require a legal, security, product, operational, or data-protection decision that is not documented in the repository.

## Agent skills

### Issue tracker

Issues live in GitHub Issues for benatouba/flakes. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout with `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
