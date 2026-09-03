#!/bin/bash
# Injects a directive at session start (and after compaction) telling Claude to
# invoke the caveman skill and communicate in caveman mode for the session.
# Also writes the on/off marker read by statusline-caveman.sh.
event=$(jq -r '.hook_event_name // empty' 2>/dev/null)
[ -z "$event" ] && event="SessionStart"

# Caveman forced on each session/compaction -> reflect in marker.
echo "on" > "$HOME/.claude/caveman.state"
context="SESSION DIRECTIVE: Invoke the caveman skill (Skill tool, skill name \"caveman\") now, before your first response, and communicate in caveman mode for the rest of this session."
jq -n --arg e "$event" --arg c "$context" \
  '{hookSpecificOutput:{hookEventName:$e, additionalContext:$c}}'
