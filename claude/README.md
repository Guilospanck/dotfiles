# claude-tools

A small collection of tooling and config for [Claude Code](https://claude.com/claude-code).

| Path | What it is |
| --- | --- |
| [`vm-claude/`](https://github.com/Guilospanck/vm-claude) | **Git submodule** — run Claude Code inside an isolated microVM, one per project. See its own README. |
| `settings.json`, `hooks/`, `skills/` | The portable, PII-free parts of the host `~/.claude` config. `~/.claude` symlinks to them, so they are the live config — see [Vendored config](#vendored-claude-config). |
| `setup-graphify.sh` | Installs [graphify](https://pypi.org/project/graphifyy/) (via `uv`) and wires it into Claude Code for one repo: builds the graph, adds auto-update hooks to the repo's `.claude/settings.json`, and ignores graph output in `.claudeignore`. Run `./setup-graphify.sh [repo-path]` (default: current directory); safe to re-run. Not part of the vendored `~/.claude` snapshot. |

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

`settings.json`, `hooks/`, and `skills/` here are the portable, non-PII parts of
the host `~/.claude`. They are the live config, not a copy: home-manager
(`nix/home.nix`) symlinks `~/.claude` to them, so an edit on either side is the
same file and shows up in `git status` here. The layout mirrors `~/.claude` so
this directory can drive `vm-claude` directly (see above).

| `~/.claude` path | Links to |
| --- | --- |
| `settings.json` | `claude/settings.json` |
| `hooks/` | `claude/hooks/` (whole directory) |
| `skills/<name>/` | `claude/skills/<name>/` (one link per tracked skill) |

`~/.claude/skills` itself stays a real directory, because it also holds skills
that must not be tracked (see below). A skill created directly in
`~/.claude/skills` is therefore local only; to track it, move it to
`claude/skills/`, `git add` it, and run `just switch` to link it back.

Claude Code writes to `settings.json` itself (`/config`, plugin installs,
permission changes), so review `git diff claude/settings.json` before
committing: no tokens in `env`, no `/Users/<name>/…` paths.

### What's in

| Path | What it is |
| --- | --- |
| `settings.json` | Global Claude config: effort, hook wiring, statusline, enabled plugins, permissions |
| `hooks/caveman-session.sh` | Injects the caveman session directive; writes the on/off marker |
| `hooks/statusline-caveman.sh` | Status line: caveman flag + model + cwd |
| `hooks/consult-llm-monitor.sh` | Opens `consult-llm-monitor` in a tmux split when Claude runs `consult-llm` |
| `skills/` | 23 personal skills (`collab`, `consult`, `workshop`, `pre-pr`, …) |

Absolute host paths in `settings.json` are written as `$HOME/.claude/…`. Claude
Code runs hook and status-line commands through a shell (shell form — no `args`),
so `$HOME` expands at run time. Keep new hooks in shell form for this to hold.

### What's excluded, and why

- **Credentials and history** — `.credentials.json`, `history.jsonl`,
  `projects/`, `sessions/`, `shell-snapshots/`, telemetry: PII / secrets.
- **Machine-managed and project-specific skills** — `skills/synced/` (synced
  from the Claude account; directory names carry account identifiers),
  `skills/graphify/` (installed by graphify itself), and
  `skills/update-llm-companion-envs/` (specific to a work repo).
- **Marketplace / plugin skills** — the skill entries in `~/.claude/skills` that
  are symlinks into `~/.agents` (`caveman`, `tdd`, `diagnose`, `write-a-skill`, …)
  come from a plugin marketplace and are managed there, so they're not vendored.
  Note `settings.json`'s caveman hook invokes the `caveman` skill, which is one of
  these — install that marketplace for caveman mode to work end to end.
