# Flakes dendritic model

Shared language for the NixOS branch/host design. Hosts select branches by name; branches carry the implementation.

## Language

**Branch**:
A named accumulator under `my.branches.<name>` holding `nixosModules` and `hmModules` (e.g. `wger`, `dns`, `desktop`).
_Avoid_: feature flag, profile, bundle

**Trunk**:
The shared base every normal machine gets (`base` plus `security` / `persist` / `secrets`).
_Avoid_: core, common, defaults

**Needs**:
A branch's declared list of other branches that must also be selected on the host; checked when the host resolves its branches, not transitive.
_Avoid_: dependency, requires

**Seam** / **Grandfathered**:
The seam is the branch interface hosts select through. A grandfathered bypass is an existing inline host module pinned by count in `cells/dev/branch-checks.nix`; new ones are rejected and each should shrink into a branch.

**Host leaf**:
The per-host `my.hosts.<name>` selection plus only hostname, disks, and hardware. It selects branches, it does not implement features.
_Avoid_: host config, machine module

**Dendritic**:
The rule that hosts select branches by name and never import feature files directly.
_Avoid_: layered, hierarchical
