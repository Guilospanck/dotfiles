#!/bin/bash
# Statusline: shows caveman on/off plus model + cwd.
# Reads marker file ~/.claude/caveman.state written by caveman-session.sh hook
# and flipped by the caveman skill on activate / "stop caveman".
input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name // "?"' 2>/dev/null)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty' 2>/dev/null)
dir=$(basename "${cwd:-$PWD}")

state="off"
f="$HOME/.claude/caveman.state"
[ -f "$f" ] && state=$(tr -d '[:space:]' < "$f")

if [ "$state" = "on" ]; then
  cave=$'\033[1;33m\xF0\x9F\xA6\xB4 CAVEMAN ON\033[0m'
else
  cave=$'\033[2m caveman off\033[0m'
fi

printf '%s  \033[2m|\033[0m  %s  \033[2m|\033[0m  \033[36m%s\033[0m' "$cave" "$model" "$dir"
