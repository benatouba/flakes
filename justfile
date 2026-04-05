set shell := ["bash", "-cu"]

default:
  @just --list

check:
  nix flake check

fmt:
  nix fmt

switch:
  nh os switch ~/projects/flakes

test:
  nh os test ~/projects/flakes

build:
  nix build .#nixosConfigurations.thinkpad.config.system.build.toplevel

diff:
  nvd diff /run/current-system ./result

update:
  nix flake update

update-secrets:
  nix flake update nix-secrets
