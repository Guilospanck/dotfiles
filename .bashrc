# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
### ------------------------- ALIASES --------------------------------------

# aliases for chronos
alias kill-chronos='lsof -t -i tcp:8080 | xargs kill && lsof -t -i tcp:3000 | xargs kill'

# alias for cat -> bat
alias cat='bat'

# alias for ls -> eza
alias ls='eza --icons --git'

# alias for fd
alias fd='fd --hidden --no=ignore --exclude .git'

# alias for vim  and vi -> neovim
alias vim='nvim'
alias vi='nvim'

# alias for godot nvim
alias gnvim='nvim --listen /tmp/godot.pipe'

# Git aliases
alias gs='git status'
alias gd='git diff'
alias gc='git commit'
alias gp='git push'
alias ga='git add'
alias grs='git restore --staged'
alias gds='git diff --staged'
# Removes Git Local Branches that are not on remote
alias grlb="git fetch --prune && git branch -vv | grep 'gone]' | awk '{print $1}' | xargs git branch -D"

# cargo watch alias
alias cwatch='cargo watch -x run'

# wasm opt (requires the binaryen-version_118 to be at root)
alias wasm-opt='~/binaryen-version_118/bin/wasm-opt'

# alias for removing docker volumes
alias dcprune='docker system prune --all --volumes -f && docker volume prune --filter all=1 -f'

### ------------------------------------------------------------------------

export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

# This will make pip require a venv always
export PIP_REQUIRE_VIRTUALENV=true

## FZF (Bash)
# Generate/load fzf bash bindings/completions
if command -v fzf >/dev/null 2>&1; then
  [ -f "$HOME/.fzf.bash" ] || fzf --bash > "$HOME/.fzf.bash"
  [ -f "$HOME/.fzf.bash" ] && source "$HOME/.fzf.bash"
fi

# FZF defaults
export FZF_DEFAULT_OPTS="--walker-skip .git,node_modules,target,.cargo --preview 'bat --color=always {}' --bind ctrl-y:accept"
export FZF_DEFAULT_COMMAND='fd --type file --follow --hidden --exclude .git'

# Open a file picked with fzf in vim
fv() {
  local file
  file="$(fzf)"
  [ -f "$file" ] && vim -- "$file" || true
}

# Enable vi mode
set -o vi
bind "set vi-ins-mode-string >"
bind "set vi-cmd-mode-string <"
bind "set show-mode-in-prompt on"
# Fix control keys in vi-insert
bind -m vi-insert '"\C-c": abort'          # Ctrl-C: cancel the line cleanly
bind -m vi-insert '"\C-l": clear-screen'   # Ctrl-L: clear screen
bind -m vi-insert '"\C-p": previous-history'
bind -m vi-insert '"\C-n": next-history'


# Set terminal title to current directory (Bash uses PROMPT_COMMAND, not zsh's precmd)
set_title() {
  echo -ne "\033]0;${PWD}\007"
}

# Run before each prompt; append if PROMPT_COMMAND already set
PROMPT_COMMAND="set_title${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
