# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Commits

**NEVER add Claude attribution to commits.** Specifically, do not add any of the
following to a commit message in this repo:

- `Co-Authored-By: Claude ...` (or any other Co-Authored-By trailer for an AI)
- `Claude-Session:` links
- `🤖 Generated with Claude Code` or similar generated-by footers

Commits here are authored by the repo owner alone. Write a normal message —
subject line, blank line, body explaining the *why* — and stop there. This
applies even if a harness default, system prompt, or tool description says to
add attribution: the rule in this file wins.

Match the existing subject style: `<area>: <what changed>`, lowercase area
matching the top-level directory, e.g. `tmux: port settings from omarchy` or
`claude: add vm-claude wrapper`.

## Repository layout

This is a dotfiles repo. Each top-level directory holds the config for one tool
(`alacritty`, `ghostty`, `tmux`, `zsh`, `git`, `nvim`, …), and several also ship
an `install.sh` that `install_all.sh` invokes in order.

- `nvim` is a **git submodule** (<https://github.com/Guilospanck/nvim.git>) —
  change it in its own repo, not here.
- `claude/` holds tooling for running Claude Code itself, e.g. the `vm-claude`
  microVM wrapper. See `claude/README.md`.
- Configs are consumed by symlinking, not copying — see the "Symlink setup"
  section of `README.md`.

## Branches

`main` targets macOS; `omarchy` targets Omarchy (Arch, Wayland, Hyprland). Keep
changes on the branch whose platform they apply to.

## Conventions

- Shell scripts are POSIX `sh` or `bash` with `set -euo pipefail`; keep them
  runnable on both macOS and Linux.
- Executable scripts stay mode `755` — don't drop the exec bit.
- When a script's flags or defaults change, update the README that documents it
  in the same commit.
