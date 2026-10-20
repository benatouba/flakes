{ config, inputs, ... }:
let
  u = config.my.user;
  gitlabPath = "${toString inputs.nix-secrets}/gitlab.nix";
in
{
  config.my.branches.base.hmModules = [
    (
      { pkgs, ... }:
      {
        programs.git = {
          enable = true;

          settings = {
            user = {
              name = u.fullName;
              inherit (u) email;
            };
            core = {
              editor = "nvim";
              whitespace = "fix,-indent-with-non-tab,trailing-space,cr-at-eol";
              preloadIndex = true;
              pager = "delta";
            };
            interactive.diffFilter = "delta --color-only";
            delta = {
              navigate = true;
              side-by-side = true;
              line-numbers = true;
              syntax-theme = "Catppuccin Mocha";
              paging = "auto";
            };
            url = {
              "git@github.com:${u.githubUser}/" = {
                insteadOf = "gh:me:";
              };
              "git@github.com:" = {
                insteadOf = "gh:";
              };
            };
            web.browser = "brave";
            init.defaultBranch = "main";
            push = {
              default = "current";
              autoSetupRemote = true;
            };
            pull.rebase = true;
            color.ui = true;
            fetch = {
              prune = true;
              pruneTags = true;
            };
            rebase.autoStash = true;
            "color \"branch\"" = {
              current = "yellow bold";
              local = "green bold";
              remote = "cyan bold";
            };
            "color \"diff\"" = {
              meta = "black bold";
              frag = "magenta bold";
              old = "red";
              new = "green bold";
              whitespace = "yellow reverse";
              context = "white";
            };
            "color \"status\"" = {
              added = "green bold";
              changed = "yellow bold";
              untracked = "red bold";
            };
            alias = {
              logo = "log --pretty=tformat:'%C(auto,red)%m %C(auto,yellow)%h%C(auto,magenta) %G? %C(auto,blue)%>(12,trunc)%ad %C(auto,green)%<(15,trunc)%aN%C(auto,reset)%s%C(auto,red) %gD %D' --date=short";
              adog = "log --all --decorate --oneline --graph";
              dog = "log --decorate --oneline --graph";
              s = "status -sb";
              c = "commit";
              cm = "commit -m";
              ac = "commit -am";
              ca = "commit --amend";
              can = "commit --amend --no-edit";
              co = "checkout";
              cb = "checkout -b";
              br = "branch";
              bra = "branch -a";
              brd = "branch -d";
              sw = "switch";
              swc = "switch -c";
              d = "diff";
              ds = "diff --staged";
              p = "push";
              pf = "push --force-with-lease";
              pl = "pull";
              st = "stash";
              stp = "stash pop";
              stl = "stash list";
              unstage = "reset HEAD --";
              undo = "reset --soft HEAD~1";
              cp = "cherry-pick";
              rb = "rebase";
              rbc = "rebase --continue";
              rba = "rebase --abort";
              cl = "clone";
              f = "fetch --all --prune";
              fp = "fetch --all --prune --prune-tags";
              up = "!git remote update --prune && git status -sb";
              t = "tag";
            };
            diff = {
              tool = "nvim_difftool";
              context = 3;
              renames = "copies";
              algorithm = "histogram";
              submodule = "log";
            };
            submodule.recurse = true;
            difftool.prompt = false;
            "difftool \"nvim_difftool\"".cmd =
              "nvim -c \"packadd nvim.difftool\" -c \"DiffTool $LOCAL $REMOTE\"";
            merge = {
              tool = "nvim_mergetool";
              conflictstyle = "diff3";
            };
            mergetool = {
              prompt = false;
              keepBackup = false;
            };
            "mergetool \"nvim_mergetool\"".cmd =
              "nvim -c \"packadd nvim.difftool\" -c \"DiffTool $LOCAL $REMOTE\"";
            credential.helper = "cache --timeout=3600";
            "filter \"lfs\"" = {
              clean = "git-lfs clean -- %f";
              smudge = "git-lfs smudge -- %f";
              process = "git-lfs filter-process";
              required = true;
            };
            help.autocorrect = 20;
          };

          ignores = [
            "**/*.sqlite3"
            "**/__pycache__"
            "**/*.pyc"
            "**/tags"
            "**/*.orig"
            "**/*.coverage*"
            ".vscode"
            "**/htmlcov*"
            ".vimspector.*"
            "node_modules/"
            "[._]*.s[a-v][a-z]"
            "[._]*.sw[a-p]"
            "Session.vim"
            "*~"
            ".fuse_hidden*"
            ".directory"
            ".Trash-*"
            ".nfs*"
            "nohup.out"
            "*.bak"
            "*.swp"
            "*.tmp"
            "__pycache__/"
            "*.py[cod]"
            ".Python"
            "build/"
            "dist/"
            "*.egg-info/"
            ".env"
            ".venv"
            "venv/"
            ".mypy_cache/"
            ".ruff_cache/"
            "**/.claude/settings.local.json"
            ".direnv/"
            ".envrc"
          ];
        };

        home.packages = with pkgs; [
          git-lfs
          delta
        ];
      }
    )
  ];

  config.my.branches.personal.hmModules = [
    (
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        hasGitlabConfig = builtins.pathExists gitlabPath;
        gitlab = if hasGitlabConfig then import gitlabPath else { };
        gitlabHost = gitlab.host;
        gitlabCredentialHelper = pkgs.writeShellScript "git-credential-private-gitlab" ''
          if [ "''${1:-}" = get ]; then
            token=$(${pkgs.rbw}/bin/rbw get ${lib.escapeShellArg gitlab.tokenEntry}) || exit 1
            printf 'username=%s\npassword=%s\n' ${lib.escapeShellArg gitlab.userName} "$token"
          fi
        '';
        glabConfig = (pkgs.formats.yaml { }).generate "glab-config.yml" {
          host = gitlabHost;
          git_protocol = "https";
          check_update = false;
          telemetry = false;
          hosts.${gitlabHost} = {
            user = gitlab.userName;
            git_protocol = "https";
            api_protocol = "https";
            api_host = gitlabHost;
            custom_headers = [
              {
                name = "PRIVATE-TOKEN";
                valueFromCommand = "${pkgs.rbw}/bin/rbw get ${lib.escapeShellArg gitlab.tokenEntry}";
              }
            ];
          };
        };
      in
      lib.mkMerge [
        {
          home.packages = [ pkgs.glab ];
          warnings = lib.optional (!hasGitlabConfig) ''
            GitLab integration needs gitlab.nix in the private nix-secrets input
            with host, userName, and tokenEntry (see secrets/gitlab.example.nix).
            Add the private metadata and update the nix-secrets input to enable it.
          '';
        }
        (lib.mkIf hasGitlabConfig {

          # The instance is HTTPS-only, including when a copied remote uses SSH.
          programs.git.settings = {
            url."https://${gitlabHost}/".insteadOf = [
              "git@${gitlabHost}:"
              "ssh://git@${gitlabHost}/"
            ];
            credential."https://${gitlabHost}" = {
              username = gitlab.userName;
              helper = [
                ""
                "${gitlabCredentialHelper}"
              ];
            };
          };

          # Private metadata comes from nix-secrets; it enters the local Nix store.
          # glab reads the existing rbw
          # entry at API-client creation, without exporting the token to the shell.
          # See secrets/gitlab.example.nix for the private metadata shape.
          # glab requires mode 0600 even for token-free config, so a normal HM
          # symlink to a world-readable store file is rejected by its parser.
          home.activation.glabConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            run ${pkgs.coreutils}/bin/install -D -m 600 ${glabConfig} \
              ${lib.escapeShellArg "${config.xdg.configHome}/glab-cli/config.yml"}
          '';
        })
      ]
    )
  ];
}
