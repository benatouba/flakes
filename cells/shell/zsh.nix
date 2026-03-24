{ ... }:
{
  config.my.hmModules = [({ pkgs, lib, ... }: {
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
          "emoji"
          "eza"
          "encode64"
          "sudo"
          "copypath"
          "web-search"
          "colored-man-pages"
          "pip"
          "ssh-agent"
          "uv"
        ];
      };

      initContent = lib.mkMerge [
        (lib.mkBefore ''
          fastfetch
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

          # Tokens (secrets — persisted in ~/.secrets/, not in flakes repo)
          [ -f ~/.secrets/tokens.zsh ] && source ~/.secrets/tokens.zsh

          # Zoxide — replace cd with zoxide's smart cd
          eval "$(zoxide init zsh --cmd cd)"

          # Case-sensitive completion
          CASE_SENSITIVE="true"
          COMPLETION_WAITING_DOTS="true"
          DISABLE_AUTO_TITLE="true"

          # ssh-agent
          zstyle ':omz:plugins:ssh-agent' 'quiet' yes
          zstyle ':omz:plugins:ssh-agent' 'lazy' yes
          zstyle ':omz:plugins:ssh-agent' agent-forwarding yes
          zstyle ':omz:plugins:eza' 'dirs-first' yes
          zstyle ':omz:plugins:eza' 'git-status' yes

          # Starship prompt
          eval "$(starship init zsh)"
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
    ];

    # direnv + nix-direnv: auto-activate per-project dev shells
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };
  })];
}
