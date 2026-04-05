{ config, ... }:
let
  u = config.my.user;
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
            pull.rebase = false;
            color.ui = true;
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
              t = "tag";
            };
            diff = {
              tool = "nvim";
              context = 3;
              renames = "copies";
              algorithm = "histogram";
              submodule = "log";
            };
            submodule.recurse = true;
            difftool.prompt = false;
            "difftool \"nvim\"".cmd = "nvim -c \"DiffviewOpen\"";
            merge = {
              tool = "diffview";
              conflictstyle = "diff3";
            };
            mergetool = {
              prompt = false;
              keepBackup = false;
            };
            "mergetool \"diffview\"".cmd = "nvim -n -c \"DiffviewOpen\" \"$MERGE\"";
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
            "**/*cache*"
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
}
