set shell := ["bash", "-cu"]

default:
  @just --list

check:
  nix flake check --checks pre-commit-check

fmt:
  nix fmt

switch:
  nh os switch ~/projects/flakes

switch-host host="thinkpad":
  nh os switch ~/projects/flakes#{{host}}

update-switch:
  just update && just switch

test:
  nh os test ~/projects/flakes

update-test:
  just update && just test

test-host host="thinkpad":
  nh os test ~/projects/flakes#{{host}}

build:
  nh os build ~/projects/flakes

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
