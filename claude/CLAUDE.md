# Global instructions

## Communication

- Spell out every shorthand, acronym, or abbreviation the first time it appears
  in a conversation (e.g. "PRM (Protected Resource Metadata)"). Use the short
  form only after that. This applies in terse/caveman mode too. Well-known
  basics (API, URL, JSON, HTTP) are exempt.
- Whenever I give you text you are meant to copy (a PR comment, a message, a
  command, a snippet), also put it on the macOS clipboard with `pbcopy` and say
  that it is there. Still show the text in the reply.

## Hooks and safety checks

- Never bypass a hook or safety check: no `--no-verify`, no `--no-gpg-sign`,
  no disabling or editing the hook, no skipping a scanner. They exist for
  security and must be respected. When one blocks a commit or action, fix the
  cause (remove the flagged content, change the code) and retry. If it looks
  like a false positive, say so and ask me; do not work around it.
- This holds for scripts and recipes you write too: do not add flags that skip
  hooks, and do not put content in them that a scanner is known to flag.

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

## Commands that can hang

A command that hangs unnoticed wastes the user's time and trust. This has
happened repeatedly (e.g. `docker run ... rustc --version` under QEMU hung for
14 minutes at 0% CPU while I said "waiting"). The rules:

- Choose the hard time limit BEFORE running anything that might not return
  (docker run/build, network calls, emulated or cross-arch work, test suites,
  any command I have not run before). Size it to a realistic worst case: 60-120 s
  for a probe such as `--version` or a smoke test, never "2 hours just in case".
- A tool timeout is not a limit. When the Bash tool "moves the command to the
  background" it keeps running. Wrap the command myself with
  `timeout -k 5 <secs> ...` (macOS: `gtimeout -k 5 ...`). Plain `timeout N` is
  not enough: `docker run` ignores SIGTERM, so the `-k` kill-after is required.
- A container needs a `--name`, and the cleanup `docker rm -f <name>` runs after
  the command, even on timeout. Killing the CLI client does not stop the
  container.
- A background job is mine to watch. Never write "waiting" or "I'll report when
  it finishes" without a check: arm a Monitor with an exit condition and a
  timeout, or check it on my next turn. When a "moved to background" notice
  arrives, look at it within the same turn (elapsed time, output growth, CPU via
  `docker stats` or `ps`) and say which it is: progressing, finished or hung.
- Hung means: elapsed time over twice the expected duration, or no new output
  and about 0% CPU for 2-3 minutes. A hung command is a failure, not "slow".
  Kill it (kill -9 if needed), confirm it is gone with `ps` and `docker ps`,
  tell the user, then diagnose.
- When I start a background job, tell the user in one line its expected
  duration, its hard limit and where its log is. When the user asks "check" or
  "status", read the log and the process state first, then answer.

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

## Sending keys to tmux panes

- Never target a tmux pane by `session:window.pane` index. Window indexes shift
  when windows open or close, and `tmux list-windows -a` spans every session
  (other projects' Claude sessions live there). Typed text in a pane that runs
  Claude lands as a chat message to that session.
- Before every `tmux send-keys`: list panes with
  `tmux list-panes -a -F '#{pane_id} #{pane_current_command} #{pane_current_path}'`,
  pick the stable pane id (`%NNN`), and confirm its path is the worktree you
  mean and its command is what you expect (`zsh` before typing a launch
  command, not a running `claude`). Re-check right before sending, not from an
  earlier listing.
- Prefer `workmux send <handle>` for agents workmux manages. After sending,
  capture the pane to confirm where the text went.
