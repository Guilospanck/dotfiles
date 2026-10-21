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
- Checking only containers, subagents and test runs is not enough; I have
  missed orphaned polling loops this way twice. Always run
  `ps -axo pid,etime,command | grep -E 'sleep|until |while |tail -f|watch ' | grep -v grep`
  plus `jobs`, and report the result, before claiming nothing is running.
- Give every polling loop a timeout or an exit condition that is certain to
  happen; do not wait on a marker that an abandoned run will never write.
- When briefing a subagent, tell it to stop its own background shells before
  it reports.

## Token economy and model selection

Spend the fewest tokens that still get the task right: use the cheapest model
that is capable of the task, and keep contexts small.

When dispatching a subagent (Agent tool, workflow, workmux agent), always set
the model explicitly:

- **Haiku:** mechanical work whose exact result is already specified — renames,
  constant or config edits, adding documented entries, transcribing complete
  code from a plan, file searches, scoped re-reviews of small fix diffs
  (under ~100 lines).
- **Sonnet (the default):** ordinary implementation from a written plan or
  spec, test writing, debugging with a clear reproduction, per-task code
  reviews, planning a well-scoped feature, orchestrating other agents.
- **Opus:** security-sensitive or concurrency/state-machine-critical code and
  its reviews, architecture and design decisions, whole-branch or milestone
  reviews, and any task a Sonnet agent has already failed twice.
- **Fable** (most expensive): only when the user asks for it.

Keep contexts small:

- Give subagents file paths, not pasted content. Have them write full reports
  to a file and return at most ~10 lines (status, commit, test counts,
  concerns).
- Do not read whole diffs or logs yourself when a reviewer or a filtered
  command (`grep`, `tail`) can answer.
- Record progress in a file (ledger) so `/compact` or `/clear` loses nothing,
  and compact long-running agent sessions periodically.
- Prefer fewer review rounds: fix rounds only for Critical/Important findings;
  batch minor ones.

# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

## Evidence before advice

- Read the actual code in every library and service involved before proposing
  any idea or design. Comments, docs, ADRs and recollection are not evidence.
- Do the full reading first. Never answer with "unverified", "did not read",
  "from memory" or "tell me and I will read it"; keep reading until the code
  answers the question. Re-check line references against the current HEAD,
  because branches get rebased mid-session.
