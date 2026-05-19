set shell := ["bash", "-cu"]
set quiet

root := justfile_directory()
secrets := env_var_or_default("NIX_SECRETS_DIR", "/home/ben/.local/secrets")
thinkpad_wol_macs := "84:a9:38:c4:5f:42 84:a9:38:c4:5f:41 e0:0a:f6:5e:5c:8f"
esprimo_wol_mac := "90:1b:0e:d5:c8:be"

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

[arg("update", long="update", short="u", value="true", help="Update flakes before running the command")]
switch update="false" host="thinkpad":
  nh os switch {{ if update == "true" { "--update" } else { "" } }} {{root}}#{{host}}

[arg("update", long="update", short="u", value="true", help="Update flakes before running the command")]
test update="false" host="thinkpad":
  nh os test {{ if update == "true" { "--update" } else { "" } }} {{root}}#{{host}}

[arg("update", long="update", short="u", value="true", help="Update flakes before running the command")]
build update="false" host="thinkpad":
  nh os build {{ if update == "true" { "-u" } else { "" } }} {{root}}#{{host}}

[arg("update", long="update", short="u", value="true", help="Update flakes before running the command")]
boot update="false" host="thinkpad":
  nh os boot {{ if update == "true" { "--update" } else { "" } }} {{root}}#{{host}}

esprimo-test:
  nixos-rebuild test --flake {{root}}#esprimo --target-host ben@esprimo --sudo

esprimo-switch:
  nixos-rebuild switch --flake {{root}}#esprimo --target-host ben@esprimo --sudo

esprimo-boot:
  nixos-rebuild boot --flake {{root}}#esprimo --target-host ben@esprimo --sudo

esprimo-switch-bootstrap:
  nixos-rebuild switch --flake {{root}}#esprimo --target-host ben@esprimo --sudo --ask-sudo-password

esprimo-switch-up:
  just update && just esprimo-switch

wake-esprimo:
  wakeonlan {{esprimo_wol_mac}}

wake-thinkpad:
  wakeonlan {{thinkpad_wol_macs}}

build-ec2-image:
  nix build .#ec2-amazon

diff:
  nvd diff /run/current-system ./result

alias up := update
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
  sops {{secrets}}/secrets.yaml

sops-rekey:
  SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-/persist/sops/age/keys.txt}" sops updatekeys {{secrets}}/secrets.yaml

secrets-sync host="thinkpad":
  just update-secrets && just test false {{host}}

sops-edit-file file="secrets/secrets.example.yaml":
  sops {{file}}

doctor:
  just check
  just fast-check
  just lint-actions
  deadnix --fail cells flake.nix
  statix check cells
