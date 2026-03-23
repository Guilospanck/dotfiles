# ──────────────────────────────────────────────
# Prompt (git-aware)
# ──────────────────────────────────────────────
autoload -Uz vcs_info add-zsh-hook

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats '%b'
zstyle ':vcs_info:git:*' actionformats '%b|%a'

function _git_prompt_info() {
  vcs_info
  [[ -z "$vcs_info_msg_0_" ]] && return

  local git_status=""
  local st
  st=$(command git status --porcelain 2>/dev/null)

  # ? = untracked, ! = modified, + = staged
  [[ -n $(echo "$st" | grep '^??') ]] && git_status+="?"
  [[ -n $(echo "$st" | grep '^ M\|^MM\|^ D') ]] && git_status+="!"
  [[ -n $(echo "$st" | grep '^M \|^A \|^D \|^R ') ]] && git_status+="+"

  # arrows for ahead/behind
  local ab
  ab=$(command git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
  local ahead=${ab%%$'\t'*}
  local behind=${ab##*$'\t'}
  [[ $ahead -gt 0 ]] && git_status+="↑"
  [[ $behind -gt 0 ]] && git_status+="↓"

  # stash indicator
  [[ -n $(command git stash list 2>/dev/null) ]] && git_status+="*"

  local info="%F{magenta}${vcs_info_msg_0_}%f"
  [[ -n "$git_status" ]] && info+=" %F{yellow}${git_status}%f"
  echo " $info"
}

setopt PROMPT_SUBST
PROMPT='%F{blue}%~%f$(_git_prompt_info) %# '

# ──────────────────────────────────────────────
# Git aliases
# ──────────────────────────────────────────────
alias ga='git add'
alias gc='git commit'
alias gs='git status'
alias gp='git push'
alias gd='git diff'
alias gds='git diff --staged'
alias gr='git restore'
alias grs='git restore --staged'
# Remove local branches that are gone from remote
alias grlb="git fetch --prune && git branch -vv | grep 'gone]' | awk '{print \$1}' | xargs git branch -D"

# ──────────────────────────────────────────────
# General aliases
# ──────────────────────────────────────────────
alias cat='bat'
alias ls='eza --icons --git'
alias vim='nvim'
alias vi='nvim'
