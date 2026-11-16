---
name: orchestrate
description: Dispatch tasks to workmux worktree agents via /worktree, monitor them from this session, and (when the user chooses) merge each finished one locally onto the current branch with conflict fixing and full cleanup. Use for /orchestrate or when the user hands over a list of tasks to run in parallel and wants them merged afterwards.
---

# Orchestrate

You are the orchestrator session. You dispatch, watch, and (on request) merge.
You do not implement tasks yourself.

## 1. Dispatch

- Group the user's tasks into worktrees by shared code area (related items
  together, unrelated ones apart). Prefer 3-8 worktrees.
- Dispatch yourself; do NOT call the `worktree` skill through the Skill tool
  (it is `disable-model-invocation` and the call is refused). Follow its
  procedure instead: do not explore the code; write one prompt file per
  worktree (`tmpfile=$(mktemp).md`, full task text, relative repo paths), then
  run `workmux add <kebab-name> -b -P <prompt-file>` from the current directory
  for each. Pass through `-a/--agent` to `workmux add` (not into the prompt).
  Tell the user the branches created.
- Every prompt must tell the agent: follow the project CLAUDE.md, commit its
  work normally when done (a failing hook is fixed, not bypassed), run tests
  once at the end, and stop its own background shells before reporting.
- Record the orchestrator branch: `git branch --show-current` (the merge target)
  and the list of dispatched worktree names.

## 2. Monitor

Start a Monitor (load via ToolSearch `select:Monitor` if deferred) in THIS
session. It must have an exit condition and a timeout (about 4 h). Poll
`workmux list` about every 60 s and emit one line only when a worktree's AGENT
state changes (working / waiting / done) or its commit count changes
(`git rev-list --count <target>..<branch>`). Exit when every dispatched worktree
is `done` or gone. Never leave an idle polling loop behind.

Example bounded loop (4 h maximum; replace `<name1>|<name2>` with the
dispatched worktree names):

    for i in $(seq 1 240); do
      out=$(workmux list); echo "$out"
      echo "$out" | grep -E '<name1>|<name2>' | grep -qi working || break
      sleep 60
    done

Diff each snapshot against the previous one and emit a line only on change. The
loop exits when no dispatched worktree is still `working`.

When something changes, tell the user briefly. A `waiting` agent needs the
user: say which one. A `done` agent with uncommitted changes: check
`git -C <worktree> status --short`; if the work looks complete, commit it
in that worktree (`git add -A`, `git commit`, with the Co-Authored-By trailer
from the session reminder). If a hook fails, fix the cause; never bypass it. Never send keys to
tmux panes by index; use `workmux send` or verified `%pane` ids.

## 3. Merge (only when the user chooses)

When all are done, ask once: merge all onto `<target>` now? Do nothing until the
user says yes (they may pick a subset or an order). Then, for each worktree,
sequentially, from the main repo directory:

    workmux merge <name> --rebase

- `--rebase` keeps history linear. By default `workmux merge` removes the
  worktree, tmux window and branch; `--keep` opts out. Pre-merge hooks run
  and are not skipped.
- Merge the smallest/least risky first; shared files such as translation
  catalogs and generated lockfiles are the usual conflict spots.
- On conflict: resolve in the worktree (rebase in progress), keep BOTH sides'
  intent (for catalogs or JSON files, union the entries), `git add`,
  `git rebase --continue`, then re-run the merge. Never discard a side's work
  or use `--force`/`git reset --hard` without telling the user.
- After all merges run the project's cheap checks once (the commands CLAUDE.md
  or the justfile name) and report failures faithfully; fix breakage caused by
  the combination.

## 4. Cleanup and report

- Verify: `git branch`, `git worktree list`, `workmux list` show no leftovers;
  remove the prompt files you created (targeted `rm` of known paths).
- Stop the monitor (TaskStop) if still alive.
- Run `ps -axo pid,etime,command | grep -E 'sleep|until |while |tail -f|watch ' | grep -v grep`
  plus `jobs`; kill anything of ours that is idle, and report the result.
- Final report: one line per worktree (merged commit, conflicts fixed), check
  results, anything killed.
