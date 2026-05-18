set shell := ["bash", "-cu"]
set quiet

default:
  @just --list

check:
  nix flake check

fast-check:
  nix-fast-build --flake .#checks --no-link

lint-actions:
  actionlint .github/workflows/ci.yml
  actionlint .github/workflows/flake-update.yml

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

build-ec2-image:
  nix build .#ec2-amazon

fast-build target=".#checks" attic_cache="":
  if [ "{{attic_cache}}" = "" ]; then nix-fast-build --flake {{target}} --no-link; else nix-fast-build --flake {{target}} --attic-cache {{attic_cache}} --no-link; fi

update-build:
  just update && just build

boot mode="":
  if [ "{{mode}}" = "" ]; then nh os boot ~/projects/flakes; elif [ "{{mode}}" = "up" ]; then nh os boot --update ~/projects/flakes; else echo "Invalid mode '{{mode}}'. Use 'up' or omit it." >&2; exit 1; fi

update-boot:
  just update && just boot

diff:
  nvd diff /run/current-system ./result

update:
  nix flake update

update-package package:
  nix-update {{package}}

prefetch-url url:
  nurl {{url}}

update-secrets:
  nix flake update nix-secrets

cache-push cache target=".#checks":
  nix build --no-link --print-out-paths {{target}} | xargs attic push {{cache}}

cache-watch cache:
  attic watch-store {{cache}}

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
  just check
  just fast-check
  just lint-actions
  deadnix --fail cells flake.nix
  statix check cells
