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
  nixos-rebuild test --flake {{root}}#esprimo --target-host ben@esprimo --sudo --ask-sudo-password

esprimo-switch:
  nixos-rebuild switch --flake {{root}}#esprimo --target-host ben@esprimo --sudo --ask-sudo-password

esprimo-boot:
  nixos-rebuild boot --flake {{root}}#esprimo --target-host ben@esprimo --sudo --ask-sudo-password

esprimo-switch-up:
  just update && just esprimo-switch

esprimo-clear-switch-unit:
  ssh -t ben@esprimo 'sudo systemctl stop nixos-rebuild-switch-to-configuration.service || true; sudo systemctl reset-failed nixos-rebuild-switch-to-configuration.service || true'

esprimo-recover-logind:
  ssh -t ben@esprimo 'sudo systemctl restart systemd-logind.service'

esprimo-paperless-superuser:
  ssh -t ben@esprimo 'sudo paperless-manage createsuperuser'

esprimo-paperless-status:
  ssh ben@esprimo 'systemctl --no-pager status paperless-web paperless-scheduler paperless-task-queue paperless-consumer'

esprimo-paperless-backup:
  ssh ben@esprimo 'sudo systemctl start borgbackup-job-paperless-office.service'

esprimo-paperless-import-dry-run source="/home/ben/documents":
  rsync -avmn --prune-empty-dirs \
    --include='*/' \
    --include='*.[Pp][Dd][Ff]' \
    --include='*.[Jj][Pp][Gg]' --include='*.[Jj][Pp][Ee][Gg]' \
    --include='*.[Pp][Nn][Gg]' \
    --include='*.[Tt][Ii][Ff]' --include='*.[Tt][Ii][Ff][Ff]' \
    --include='*.[Ww][Ee][Bb][Pp]' \
    --include='*.[Tt][Xx][Tt]' \
    --include='*.[Dd][Oo][Cc]' --include='*.[Dd][Oo][Cc][Xx]' \
    --include='*.[Oo][Dd][Tt]' \
    --include='*.[Xx][Ll][Ss]' --include='*.[Xx][Ll][Ss][Xx]' \
    --include='*.[Oo][Dd][Ss]' \
    --include='*.[Pp][Pp][Tt]' --include='*.[Pp][Pp][Tt][Xx]' \
    --include='*.[Oo][Dd][Pp]' \
    --include='*.[Ee][Mm][Ll]' \
    --exclude='*' \
    "{{source}}/" ben@esprimo:/tmp/paperless-import-dry-run/

esprimo-paperless-import source="/home/ben/documents":
  stamp=$(date +%Y%m%d-%H%M%S); \
  remote="/tmp/paperless-import-$stamp"; \
  rsync -avm --prune-empty-dirs \
    --include='*/' \
    --include='*.[Pp][Dd][Ff]' \
    --include='*.[Jj][Pp][Gg]' --include='*.[Jj][Pp][Ee][Gg]' \
    --include='*.[Pp][Nn][Gg]' \
    --include='*.[Tt][Ii][Ff]' --include='*.[Tt][Ii][Ff][Ff]' \
    --include='*.[Ww][Ee][Bb][Pp]' \
    --include='*.[Tt][Xx][Tt]' \
    --include='*.[Dd][Oo][Cc]' --include='*.[Dd][Oo][Cc][Xx]' \
    --include='*.[Oo][Dd][Tt]' \
    --include='*.[Xx][Ll][Ss]' --include='*.[Xx][Ll][Ss][Xx]' \
    --include='*.[Oo][Dd][Ss]' \
    --include='*.[Pp][Pp][Tt]' --include='*.[Pp][Pp][Tt][Xx]' \
    --include='*.[Oo][Dd][Pp]' \
    --include='*.[Ee][Mm][Ll]' \
    --exclude='*' \
    "{{source}}/" "ben@esprimo:$remote/"; \
  ssh -t ben@esprimo "sudo mkdir -p /var/lib/paperless/consume/import && sudo rsync -a '$remote/' /var/lib/paperless/consume/import/ && sudo chown -R paperless:paperless /var/lib/paperless/consume/import && rm -rf '$remote'"

esprimo-finance-status:
  ssh ben@esprimo 'systemctl --no-pager status finance-bootstrap fava finance-import.service finance-import.timer'

esprimo-finance-import:
  ssh -t ben@esprimo 'sudo systemctl start finance-import.service'

esprimo-postbank-sync-dry-run source="/home/ben/documents/postbank":
  rsync -avmn --delete \
    --include='*/' \
    --include='Kontoauszug_*.pdf' \
    --exclude='*' \
    "{{source}}/" ben@esprimo:/tmp/postbank-sync-dry-run/

esprimo-postbank-sync source="/home/ben/documents/postbank":
  stamp=$(date +%Y%m%d-%H%M%S); \
  remote="/tmp/postbank-sync-$stamp"; \
  rsync -avm --delete \
    --include='*/' \
    --include='Kontoauszug_*.pdf' \
    --exclude='*' \
    "{{source}}/" "ben@esprimo:$remote/"; \
  ssh -t ben@esprimo "sudo mkdir -p /var/lib/finance/sources/postbank && sudo rsync -a --delete '$remote/' /var/lib/finance/sources/postbank/ && sudo chown -R finance:finance /var/lib/finance/sources/postbank && rm -rf '$remote'"

esprimo-postbank-refresh source="/home/ben/documents/postbank":
  just esprimo-postbank-sync "{{source}}" && just esprimo-finance-import

esprimo-finance-check:
  ssh -t ben@esprimo 'sudo -u finance bean-check /var/lib/finance/ledger/main.beancount'

esprimo-finance-tunnel:
  ssh -N -L 5000:127.0.0.1:5000 ben@esprimo

esprimo-stirling-status:
  ssh ben@esprimo 'systemctl --no-pager status stirling-pdf'

esprimo-syncthing-tunnel:
  ssh -N -L 8384:127.0.0.1:8384 ben@esprimo

esprimo-wger-status:
  ssh ben@esprimo 'systemctl --no-pager status docker-wger-db docker-wger-cache docker-wger-web docker-wger-nginx docker-wger-celery-worker docker-wger-celery-beat wger-db-backup.timer'

esprimo-wger-logs service="web":
  ssh -t ben@esprimo "sudo docker logs --tail=200 --follow wger-{{service}}"

esprimo-wger-backup:
  ssh -t ben@esprimo 'sudo systemctl start wger-db-backup.service'

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
