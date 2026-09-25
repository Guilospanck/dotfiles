export GOPATH=$HOME/golang
export GOROOT=/opt/homebrew/opt/go/libexec
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$GOROOT/bin
export PATH="/usr/local/bin:/usr/local/sbin:~/bin:$PATH"

export EDITOR=nvim

autoload edit-command-line
zle -N edit-command-line
bindkey '^Xe' edit-command-line

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
alias git-prune="git fetch --prune && git branch -vv | grep 'gone]' | awk '{print $1}' | xargs git branch -D"

# cargo watch alias
alias cwatch='cargo watch -x run'

# wasm opt 
alias wasm-opt='~/binaryen-version_118/bin/wasm-opt'

# z
. $HOMEBREW_PREFIX/etc/profile.d/z.sh

export PATH="/opt/homebrew/opt/node@16/bin:$PATH"

# alias for caffeinate - prevents mac from sleeping
alias kaffee='caffeinate -disu'

### nvm
  export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion


### asdf
# . /opt/homebrew/opt/asdf/libexec/asdf.sh


### dive
export DOCKER_HOST=unix://$HOME/.colima/docker.sock

### docker and colima
export DOCKER_HOST="unix://$HOME/.colima/docker.sock"

alias startcolima='colima start --network-address --vm-type vz --cpu 8 --memory 12'

# Nix
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
   . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi
# End Nix


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
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# .NET 
export DOTNET_ROOT=/usr/local/share/dotnet
export PATH=$PATH:$DOTNET_ROOT

# Secretive
export SSH_AUTH_SOCK=$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh

# Prevent telemetry (when true) on Github CLI - and maybe other tools
# NOTE: if this is 'true', claude /remote-control won't work.
export DO_NOT_TRACK=false

alias md='glow -p'

# odin
odin-check() {
  find . -name '*.odin' -exec dirname {} \; | sort -u | while read -r d; do
    odin check "$d" -no-entry-point
  done
}

# workmux
alias wm='workmux'

# microsandbox
alias vm='msb'

### CLEANUPS: remove unused things (mostly) ####
# Full dev cache cleanup. Everything removed here is re-downloaded/rebuilt on demand.
#   cleanup-caches            clean package/tool caches
#   cleanup-caches --dry-run  show what would run, change nothing
#   cleanup-caches --deep     also: Docker prune, node_modules + Rust target/ in ~/repos older than 15 days
cleanup-caches() {
  local dry=0 deep=0 arg
  for arg in "$@"; do
    case $arg in
      -n|--dry-run) dry=1 ;;
      -d|--deep)    deep=1 ;;
      -h|--help)    print "usage: cleanup-caches [--dry-run] [--deep]"; return 0 ;;
      *)            print -u2 "unknown option: $arg"; return 1 ;;
    esac
  done

  local vol=/System/Volumes/Data
  local before=$(df -k $vol | awk 'NR==2 {print $4}')

  # run a command (or just print it in dry-run mode)
  _cc_run() {
    print -P "%F{cyan}→%f $*"
    (( dry )) && return 0
    # no stdin: a hidden prompt (e.g. corepack download) fails instead of hanging
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0 "$@" </dev/null >/dev/null 2>&1 \
      || print -P "  %F{yellow}(failed, skipped)%f"
  }
  # remove paths that exist
  _cc_rm() {
    local p
    for p in "$@"; do [[ -e $p ]] && _cc_run rm -rf -- "$p"; done
  }
  _cc_has() { command -v "$1" >/dev/null 2>&1 }

  print -P "%B== Package managers%b"
  _cc_has npm    && _cc_run npm cache clean --force
  _cc_has yarn   && _cc_run yarn cache clean
  _cc_rm ~/.yarn/berry/cache
  _cc_has pnpm   && _cc_run pnpm store prune
  _cc_rm ~/.bun/install/cache  # `bun pm cache rm` needs a package.json
  _cc_has pip3   && _cc_run pip3 cache purge
  _cc_has uv     && _cc_run uv cache clean
  _cc_rm ~/Library/Caches/pypoetry/cache ~/Library/Caches/pypoetry/artifacts
  _cc_has go     && _cc_run go clean -cache -modcache
  _cc_rm ~/.cargo/registry/cache ~/.cargo/registry/src
  _cc_has brew   && _cc_run brew cleanup -s --prune=all

  print -P "%B== Tool caches%b"
  _cc_has pre-commit && _cc_run pre-commit clean
  _cc_rm ~/.cache/act ~/.cache/actcache ~/.cache/puppeteer \
         ~/Library/Caches/ms-playwright ~/Library/Caches/Cypress \
         ~/Library/Caches/colima ~/Library/Caches/Google

  print -P "%B== Xcode%b"
  _cc_rm ~/Library/Developer/Xcode/DerivedData
  _cc_has xcrun && _cc_run xcrun simctl delete unavailable

  if (( deep )); then
    print -P "%B== Deep: Docker (images + build cache, volumes kept)%b"
    if _cc_has docker && docker info >/dev/null 2>&1; then
      _cc_run docker system prune -af
      _cc_has colima && colima status >/dev/null 2>&1 && _cc_run colima ssh -- sudo fstrim -a
    else
      print "  docker not running, skipped (start colima first)"
    fi

    print -P "%B== Deep: stale build dirs in ~/repos (>15 days)%b"
    if [[ -d ~/repos ]]; then
      local -a stale
      stale=(${(f)"$(command find ~/repos \
        \( -name node_modules -type d -prune -mtime +15 -print \) -o \
        \( -name target -type d -prune -mtime +15 -exec test -f {}/../Cargo.toml \; -print \) \
        2>/dev/null)"})
      if (( ${#stale} )); then
        _cc_rm "${stale[@]}"
      else
        print "  nothing stale"
      fi
    fi
  fi

  print -P "%B== Time Machine local snapshots%b"
  _cc_run tmutil thinlocalsnapshots / 999999999999 4

  if (( ! dry )); then
    local after=$(df -k $vol | awk 'NR==2 {print $4}')
    printf "\nFreed: %.1f GB (now %.1f GB free)\n" \
      $(( (after - before) / 1048576.0 )) $(( after / 1048576.0 ))
  fi

  unfunction _cc_run _cc_rm _cc_has
}
# cleanup time machine
alias tmprune='tmutil thinlocalsnapshots / 999999999999 4'
# alias for removing docker volumes
alias dcprune='docker system prune --all --volumes -f && docker volume prune --filter all=1 -f'
# alias for pruning simulator/XCode things
alias xcodeprune='rm -rf ~/Library/Developer/Xcode/DerivedData and xcrun simctl delete unavailable'
# remove old (+15 days) node_modules
alias nodeprune='cd ~/repos && find . -name node_modules -type d -prune -mtime +15 -print -exec rm -rf {} +'
# remove old (+15 days) rust target
alias rustprune='cd ~/repos && find . -name target -type d -prune -mtime +15 -exec test -f {}/../Cargo.toml \; -print -exec rm -rf {} +'

# Machine-local config and secrets (not tracked)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
