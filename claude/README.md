# claude-tools

A small collection of tooling and config for [Claude Code](https://claude.com/claude-code).

| Path | What it is |
| --- | --- |
| [`vm-claude/`](https://github.com/Guilospanck/vm-claude) | **Git submodule** — run Claude Code inside an isolated microVM, one per project. See its own README. |
| `settings.json`, `hooks/`, `skills/` | A version-controlled snapshot of the portable, PII-free parts of the host `~/.claude` config — see [Vendored config](#vendored-claude-config). |

## vm-claude

`vm-claude` lives in its own repository and is included here as a git submodule
at [`claude/vm-claude`](https://github.com/Guilospanck/vm-claude). Change it in
that repo, not here. After cloning this repo, pull it in with:

```bash
git submodule update --init claude/vm-claude
```

Install it onto your `PATH` with `just install-vm-claude` (copy) or
`just link-vm-claude` (symlink that tracks submodule edits). Full documentation
is in `claude/vm-claude/README.md`.

The vendored config below mirrors `~/.claude`, so this directory can drive
`vm-claude` directly:

```bash
CLAUDE_VM_CONFIG_DIR=~/dotfiles/claude vm-claude
```

---

## Vendored `~/.claude` config

`settings.json`, `hooks/`, and `skills/` here are a version-controlled snapshot
of the portable, non-PII parts of the host `~/.claude`. The layout mirrors
`~/.claude` so this directory can drive `vm-claude` directly (see above).

### What's in

| Path | What it is |
| --- | --- |
| `settings.json` | Global Claude config: model, effort, hook wiring, statusline, enabled plugins, permissions |
| `hooks/caveman-session.sh` | Injects the caveman session directive; writes the on/off marker |
| `hooks/statusline-caveman.sh` | Status line: caveman flag + model + cwd |
| `skills/` | 23 personal skills (`collab`, `consult`, `workshop`, `pre-pr`, …) |

Absolute host paths in `settings.json` are written as `$HOME/.claude/…`. Claude
Code runs hook and status-line commands through a shell (shell form — no `args`),
so `$HOME` expands at run time. Keep new hooks in shell form for this to hold.

### What's excluded, and why

- **Credentials and history** — `.credentials.json`, `history.jsonl`,
  `projects/`, `sessions/`, `shell-snapshots/`, telemetry: PII / secrets.
- **`hooks/peon-ping/`** — the peon-ping hook is installed
  via Homebrew (`/opt/homebrew`, `~/.openpeon`) and is a tree of symlinks + local
  state, not hand-authored config. `settings.json` still *references*
  `$HOME/.claude/hooks/peon-ping/peon.sh`, so install peon-ping separately for
  those hooks to fire; if it's absent the hooks just no-op.
- **Marketplace / plugin skills** — the skill entries in `~/.claude/skills` that
  are symlinks into `~/.agents` (`caveman`, `tdd`, `diagnose`, `write-a-skill`, …)
  come from a plugin marketplace and are managed there, so they're not vendored.
  Note `settings.json`'s caveman hook invokes the `caveman` skill, which is one of
  these — install that marketplace for caveman mode to work end to end.
