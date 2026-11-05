#!/usr/bin/env bash
# setup-graphify.sh - install graphify and wire it into Claude Code for a repo.
#
# Usage:   ./setup-graphify.sh [repo-path]     (default: current directory)
# Windows: run from Git Bash (comes with Git for Windows; Claude Code needs it anyway).
#
# Safe to re-run: upgrades graphify, rebuilds the graph, and skips hooks/ignore
# lines that already exist.

set -euo pipefail

REPO="${1:-.}"
HOOK_CMD='graphify update . >/dev/null 2>&1'

log() { printf '\n==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# --- Detect OS --------------------------------------------------------------
case "$(uname -s)" in
  Linux*)               OS=linux ;;
  Darwin*)              OS=macos ;;
  MINGW*|MSYS*|CYGWIN*) OS=windows ;;
  *) die "unsupported OS: $(uname -s)" ;;
esac
log "Detected $OS"

[ -d "$REPO" ] || die "repo not found: $REPO"
REPO="$(cd "$REPO" && pwd)"

# Convert a Windows path (C:\Users\...) to a Git Bash path; no-op elsewhere.
to_unix() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -u "$1"; else printf '%s' "$1"; fi
}

# find_bin NAME DIR... : if NAME isn't on PATH, look in DIRs and prepend the
# first one that has it. Handles .exe on Windows.
find_bin() {
  local name=$1; shift
  command -v "$name" >/dev/null 2>&1 && return 0
  local d
  for d in "$@"; do
    [ -n "$d" ] || continue
    if [ -x "$d/$name" ] || [ -x "$d/$name.exe" ]; then
      export PATH="$d:$PATH"
      hash -r
      printf '  found %s in %s (added to PATH for this run)\n' "$name" "$d"
      return 0
    fi
  done
  return 1
}

WIN_HOME=""
[ -n "${USERPROFILE:-}" ] && WIN_HOME="$(to_unix "$USERPROFILE")"

# Everywhere the uv installer may put its binary
UV_DIRS=(
  "${UV_INSTALL_DIR:-}"
  "${XDG_BIN_HOME:-}"
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "${WIN_HOME:+$WIN_HOME/.local/bin}"
  "${WIN_HOME:+$WIN_HOME/.cargo/bin}"
)

# --- 1. uv ------------------------------------------------------------------
find_bin uv "${UV_DIRS[@]}" || true   # maybe installed but not on PATH yet
if ! command -v uv >/dev/null 2>&1; then
  log "Installing uv"
  if [ "$OS" = windows ]; then
    powershell.exe -NoProfile -ExecutionPolicy ByPass -Command \
      "irm https://astral.sh/uv/install.ps1 | iex"
  else
    command -v curl >/dev/null 2>&1 || die "curl is required"
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi
  hash -r
  find_bin uv "${UV_DIRS[@]}" || die "uv installed but couldn't locate it - check the installer output above"
else
  log "uv already installed"
fi

# --- 2. graphify (package is 'graphifyy', double y) -------------------------
log "Installing/upgrading graphify"
uv tool install --upgrade graphifyy
uv tool update-shell >/dev/null 2>&1 || true   # persists PATH for future terminals
hash -r
TOOL_BIN="$(to_unix "$(uv tool dir --bin | tr -d '\r')")"   # exact dir uv puts tools in
find_bin graphify "$TOOL_BIN" "${UV_DIRS[@]}" \
  || die "graphify installed but couldn't locate it (expected in $TOOL_BIN)"

# --- 3. Register the skill with Claude Code ---------------------------------
log "Registering graphify skill with Claude Code"
graphify install

# --- 4. Build the graph + wire Claude Code in this repo ---------------------
cd "$REPO"
log "Building graph for $REPO (code only, local, no API key)"
graphify extract . --code-only

log "Wiring Claude Code to prefer the graph"
graphify claude install --project

# --- 5. Merge auto-update hooks into .claude/settings.json ------------------
log "Adding auto-update hooks to .claude/settings.json"
mkdir -p .claude
uv run --no-project python - "$HOOK_CMD" <<'PY'
import json, os, sys

cmd = sys.argv[1]
path = os.path.join(".claude", "settings.json")

data = {}
if os.path.exists(path):
    with open(path, encoding="utf-8") as f:
        text = f.read().strip()
    if text:
        data = json.loads(text)

hooks = data.setdefault("hooks", {})

def has_cmd(entries):
    return any(h.get("command") == cmd for e in entries for h in e.get("hooks", []))

wanted = {
    "UserPromptSubmit": {"hooks": [{"type": "command", "command": cmd}]},
    "PostToolUse": {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [{"type": "command", "command": cmd}],
    },
}

for event, entry in wanted.items():
    entries = hooks.setdefault(event, [])
    if not has_cmd(entries):
        entries.append(entry)
        print(f"  added {event} hook")
    else:
        print(f"  {event} hook already present")

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY

# --- 6. Keep graph output out of Claude Code's prompt cache -----------------
log "Updating .claudeignore"
if [ -s .claudeignore ] && [ -n "$(tail -c1 .claudeignore)" ]; then
  echo >> .claudeignore   # file didn't end with a newline
fi
for line in 'graphify-out/' 'graph.json'; do
  grep -qxF "$line" .claudeignore 2>/dev/null || printf '%s\n' "$line" >> .claudeignore
done

log "Done. Open a new terminal, then run 'claude' in $REPO"
