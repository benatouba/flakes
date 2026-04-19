set shell := ["bash", "-cu"]
set quiet

default:
  @just --list

check:
  nix flake check

fmt:
  nix fmt

switch mode="":
  if [ "{{mode}}" = "" ]; then nh os switch ~/projects/flakes; elif [ "{{mode}}" = "up" ]; then nh os switch --update ~/projects/flakes; else echo "Invalid mode '{{mode}}'. Use 'up' or omit it." >&2; exit 1; fi

switch-host host="thinkpad":
  nh os switch ~/projects/flakes#{{host}}

update-switch:
  just update && just switch

test mode="":
  if [ "{{mode}}" = "" ]; then nh os test ~/projects/flakes; elif [ "{{mode}}" = "up" ]; then nh os test --update ~/projects/flakes; else echo "Invalid mode '{{mode}}'. Use 'up' or omit it." >&2; exit 1; fi

update-test:
  just update && just test

test-host host="thinkpad":
  nh os test ~/projects/flakes#{{host}}

build mode="":
  if [ "{{mode}}" = "" ]; then nh os build ~/projects/flakes; elif [ "{{mode}}" = "up" ]; then nh os build --update ~/projects/flakes; else echo "Invalid mode '{{mode}}'. Use 'up' or omit it." >&2; exit 1; fi

update-build:
  just update && just build

diff:
  nvd diff /run/current-system ./result

update:
  nix flake update

update-secrets:
  nix flake update nix-secrets

nh-clean:
  nh clean all --keep-since 7d --keep 5

sops-edit:
  sops /home/ben/.local/secrets/secrets.yaml

sops-rekey:
  sops updatekeys /home/ben/.local/secrets/secrets.yaml

secrets-sync host="thinkpad":
  just update-secrets && just test-host {{host}}

sops-edit-file file="secrets/secrets.example.yaml":
  sops {{file}}

doctor:
  just check && deadnix --fail cells flake.nix && statix check cells
