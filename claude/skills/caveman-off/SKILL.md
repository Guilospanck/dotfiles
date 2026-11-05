---
name: caveman-off
description: Deactivate caveman mode and return to normal prose. Use when user says "caveman off", "stop caveman", "normal mode", or invokes /caveman-off.
---

# Caveman Off

Turn caveman mode off. Resume normal, full-sentence prose for rest of session.

## Steps

1. Set marker off (drives TUI statusline):
   ```bash
   echo off > ~/.claude/caveman.state
   ```
2. Stop caveman behavior. Articles, conjunctions, normal pleasantries return. No more fragment/arrow style.
3. Confirm briefly in normal prose, e.g. "Caveman mode off — back to normal."

## Notes

- Stays off for rest of session unless user re-triggers caveman ("caveman mode", "/caveman").
- The SessionStart hook re-enables caveman on next session/compaction by design; this skill only affects the current session.
