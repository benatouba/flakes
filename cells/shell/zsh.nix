_: {
  config.my.branches.base.nixosModules = [
    (
      { pkgs, ... }:
      {
        programs.zsh.enable = true;
        environment = {
          binsh = "${pkgs.dash}/bin/dash";
          shells = with pkgs; [ zsh ];
        };
      }
    )
  ];

  config.my.branches.base.hmModules = [
    (
      { pkgs, lib, ... }:
      {
        programs.zsh = {
          enable = true;
          autosuggestion.enable = true;
          syntaxHighlighting.enable = true;
          enableCompletion = true;

          history = {
            path = "$HOME/.local/state/zsh/.zsh_history";
            size = 100000;
            save = 100000;
            ignoreDups = true;
            ignoreAllDups = true;
            share = true;
          };

          oh-my-zsh = {
            enable = true;
            plugins = [
              "fzf"
              "zoxide"
              "git"
              "tmux"
              "history"
              "eza"
              "sudo"
              "copypath"
              "web-search"
              "colored-man-pages"
              "ssh-agent"
              "uv"
            ];
          };

          initContent = lib.mkMerge [
            (lib.mkBefore ''
              [[ -o login ]] && fastfetch
            '')
            ''
              # Custom zsh modules
              [ -f ~/.zsh/export.zsh ] && source ~/.zsh/export.zsh
              [ -f ~/.zsh/settings.zsh ] && source ~/.zsh/settings.zsh
              [ -f ~/.zsh/functions.zsh ] && source ~/.zsh/functions.zsh
              [ -f ~/.zsh/fzf.zsh ] && source ~/.zsh/fzf.zsh
              [ -f ~/.zsh/github.zsh ] && source ~/.zsh/github.zsh
              [ -f ~/.zsh/bindings.zsh ] && source ~/.zsh/bindings.zsh
              [ -f ~/.zsh/alias.zsh ] && source ~/.zsh/alias.zsh

              # Tokens (in nix-secrets repo, not in flakes)
              [ -f ~/.local/secrets/tokens.zsh ] && source ~/.local/secrets/tokens.zsh

              # Zoxide — replace cd with zoxide's smart cd
              eval "$(zoxide init zsh --cmd cd)"

              # Case-sensitive completion
              CASE_SENSITIVE="true"
              COMPLETION_WAITING_DOTS="true"
              DISABLE_AUTO_TITLE="true"

              # ssh-agent
              zstyle ':omz:plugins:ssh-agent' 'quiet' yes
              zstyle ':omz:plugins:ssh-agent' 'lazy' yes
              zstyle ':omz:plugins:ssh-agent' agent-forwarding no
              zstyle ':omz:plugins:eza' 'dirs-first' yes
              zstyle ':omz:plugins:eza' 'git-status' yes

              # pay-respects — correct previous command with F
              eval "$(pay-respects zsh --alias f)"

              # direnv (optimized): refresh on startup + directory changes only.
              # This avoids running `direnv export zsh` before every prompt.
              if (( $+commands[direnv] )); then
                _direnv_chpwd_hook() {
                  eval "$(direnv export zsh)"
                }

                autoload -U add-zsh-hook
                add-zsh-hook chpwd _direnv_chpwd_hook
                _direnv_chpwd_hook
              fi

              # Starship prompt
              eval "$(starship init zsh)"

              # Keep arrow keys on native zsh history search.
              bindkey '^[[A' up-line-or-beginning-search
              bindkey '^[[B' down-line-or-beginning-search
            ''
          ];
        };

        # Deploy custom zsh modules from flakes dotfiles
        home.file.".zsh" = {
          source = ../../dotfiles/zsh;
          recursive = true;
        };

        home.packages = with pkgs; [
          starship
          zoxide
          fzf
          bat
          vivid
          tldr
          pay-respects
          nh
          comma
        ];

        home.shellAliases = {
          dreload = "direnv reload";
          ncheck = "nh os test ~/projects/flakes";
          nswitch = "nh os switch ~/projects/flakes";
          ndiff = "nvd diff /run/current-system result";

          sops-edit = "sops ~/projects/flakes/secrets/secrets.example.yaml";
          sops-update = "just update-secrets";
        };

        home.sessionVariables = {
          WEZTERM_SHELL_SKIP_USER_VARS = "1";
        };

        # direnv + nix-direnv: auto-activate per-project dev shells
        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
          enableZshIntegration = false;
        };
      }
    )
  ];
}
