# Global instructions

## Communication

- Spell out every shorthand, acronym, or abbreviation the first time it appears
  in a conversation (e.g. "PRM (Protected Resource Metadata)"). Use the short
  form only after that. This applies in terse/caveman mode too. Well-known
  basics (API, URL, JSON, HTTP) are exempt.

## Background work

- Never leave background shells, containers, or subagents running once their
  result is no longer needed. The status line shows them as "shells" / agents
  still running, and I wait on them thinking work is in progress.
- Before saying a task is done, or that nothing is running, list what is
  actually alive: background shells (including idle `sleep`/`until` polling
  loops), containers, and subagents and the shells they started. Kill anything
  that is idle or orphaned and say what was killed.
- Give every polling loop a timeout or an exit condition that is certain to
  happen; do not wait on a marker that an abandoned run will never write.
- When briefing a subagent, tell it to stop its own background shells before
  it reports.

# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.
