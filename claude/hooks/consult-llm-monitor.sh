#!/usr/bin/env bash
# PreToolUse(Bash) hook: when Claude runs consult-llm, open consult-llm-monitor
# in a tmux split next to Claude's pane so the remote LLM's progress is visible live.
# Never blocks the tool call: always exits 0 with no stdout.

cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0

# Must invoke consult-llm itself (not consult-llm-monitor), outside tmux → no-op.
printf '%s' "$cmd" | grep -Eq '(^|[|;&( [:space:]])consult-llm([[:space:]]|$)' || exit 0
# Skip modes that don't call an LLM.
printf '%s' "$cmd" | grep -Eq 'consult-llm[[:space:]]+(models|doctor|config|docs|update|init-[a-z]+|install-skills|help)([[:space:]]|$)' && exit 0
printf '%s' "$cmd" | grep -Eq -- '(^|[[:space:]])--web([[:space:]]|$)' && exit 0

[ -n "$TMUX" ] && [ -n "$TMUX_PANE" ] || exit 0
command -v tmux >/dev/null 2>&1 || exit 0
monitor=$(command -v consult-llm-monitor) || exit 0

# Reuse monitor pane already open in this window (tagged via pane user option).
if tmux list-panes -t "$TMUX_PANE" -F '#{@consult_monitor}' 2>/dev/null | grep -qx 1; then
  exit 0
fi

pane=$(tmux split-window -h -d -l 40% -t "$TMUX_PANE" -P -F '#{pane_id}' "$monitor" 2>/dev/null) || exit 0
tmux set-option -p -t "$pane" @consult_monitor 1 2>/dev/null
exit 0
