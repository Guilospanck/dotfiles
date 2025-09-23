# # If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export GOPATH=$HOME/golang
export GOROOT=/opt/homebrew/opt/go/libexec
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$GOROOT/bin
export PATH="/usr/local/bin:/usr/local/sbin:~/bin:$PATH"

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

# z
. $HOMEBREW_PREFIX/etc/profile.d/z.sh

export PATH="/opt/homebrew/opt/node@16/bin:$PATH"

### dive
export DOCKER_HOST=unix://$HOME/.colima/docker.sock

### docker and colima
export DOCKER_HOST="unix://$HOME/.colima/docker.sock"

export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

# This will make pip require a venv always
export PIP_REQUIRE_VIRTUALENV=true

# plugin for zsh vi node
source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

## Starship
eval "$(starship init zsh)"

## FZF
fzf --zsh > ~/.fzf.zsh
export FZF_DEFAULT_OPTS="--walker-skip .git,node_modules,target,.cargo --preview 'bat --color=always {}' --bind ctrl-y:accept"
export FZF_DEFAULT_COMMAND='fd --type file --follow --hidden --exclude .git' 
function fv(){ file=$(fzf); [ -f "$file" ] && vim $file || true }
zvm_after_init_commands+=('[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh')

# Function to set the terminal title to the current directory
function set_title() {
    echo -ne "\033]0;${PWD}\007"
}

# Set the title for every command prompt
precmd() { set_title }

# bun completions
[ -s "/Users/guilospanck/.bun/_bun" ] && source "/Users/guilospanck/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# .NET 
export DOTNET_ROOT=/usr/local/share/dotnet
export PATH=$PATH:$DOTNET_ROOT
