# 1. Native Arch Shell Integration
source <(fzf --zsh)

# 2. Optimized Search (Respects .gitignore, includes hidden)
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# 3. Catppuccin Mocha Colors & Basic Ops
export FZF_DEFAULT_OPTS="--ansi --height 40% --layout=reverse --border \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

# 4. Enhanced CTRL-T (Preview with bat)
# Added --map-syntax for your Rmd files as discussed!
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :500 --map-syntax \"*.Rmd:Markdown\" {}'"

# 5. Faster ALT-C (Directory search)
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow'
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# 6. fzf-tab (Modern replacements)
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath'
zstyle ':fzf-tab:*' switch-group ',' '.'

# 7. Atuin + fzf history (snappy Ctrl-R)
if [[ -o interactive ]]; then
  _atuin_fzf_history_widget() {
    emulate -L zsh
    setopt localoptions pipefail no_aliases

    if ! (( $+commands[atuin] )); then
      zle history-incremental-search-backward
      return
    fi

    local query selected
    local -a atuin_cmd

    query=$LBUFFER
    atuin_cmd=(atuin search --cmd-only --limit 20000 --search-mode prefix)
    [[ -n $query ]] && atuin_cmd+=("$query")

    selected="$(${atuin_cmd[@]} 2>/dev/null | fzf \
      --height 45% \
      --layout=reverse \
      --border \
      --prompt='atuin> ' \
      --query="$query" \
      --bind='ctrl-r:toggle-sort' \
      --bind='tab:down,btab:up')"

    [[ -z $selected ]] && return

    LBUFFER=$selected
    zle redisplay
  }

  zle -N atuin-fzf-history-widget _atuin_fzf_history_widget
  bindkey '^R' atuin-fzf-history-widget
fi
