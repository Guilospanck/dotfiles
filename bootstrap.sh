#!/usr/bin/env bash
# bootstrap.sh - set up a Mac from zero: Xcode CLT, Nix, this repo, then
# nix-darwin + home-manager + Homebrew via the flake.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Guilospanck/dotfiles/main/bootstrap.sh | bash
#
# Env:
#   DOTFILES_DIR  where to clone the repo (default ~/repos/MyRepositories/dotfiles;
#                 the flake links configs from this path, so keep them in sync)
#   FLAKE_HOST    darwinConfigurations entry to apply (default: mac)
#
# Safe to re-run: every step checks before acting.

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/repos/MyRepositories/dotfiles}"
FLAKE_HOST="${FLAKE_HOST:-mac}"
REPO_URL="https://github.com/Guilospanck/dotfiles.git"
NVIM_URL="https://github.com/Guilospanck/kickstart-modular.nvim.git"

log() { printf '\n==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
warn() { printf 'warning: %s\n' "$*" >&2; }
# Run an optional step; report a failure but keep going.
try() { "$@" || warn "failed (skipped): $*"; }

[ "$(uname -s)" = Darwin ] || die "macOS only (use the omarchy branch on Arch)"

# --- 1. Xcode Command Line Tools (git, compilers) ---------------------------
if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Xcode Command Line Tools (accept the dialog)"
  xcode-select --install || true
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
else
  log "Xcode Command Line Tools already installed"
fi

# --- 1b. Rosetta (colima runs amd64 images through it) -----------------------
if [ "$(uname -m)" = arm64 ] && [ ! -d /Library/Apple/usr/share/rosetta ]; then
  log "Installing Rosetta"
  try softwareupdate --install-rosetta --agree-to-license
fi

# --- 2. Nix -----------------------------------------------------------------
if ! command -v nix >/dev/null 2>&1; then
  if [ ! -e /nix/var/nix/profiles/default/bin/nix ]; then
    log "Installing Nix (Determinate Systems installer)"
    curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
  fi
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
else
  log "Nix already installed"
fi

# --- 3. This repo -----------------------------------------------------------
if [ -d "$DOTFILES_DIR/.git" ]; then
  log "Updating $DOTFILES_DIR"
  git -C "$DOTFILES_DIR" pull --ff-only
  git -C "$DOTFILES_DIR" submodule update --init --recursive
else
  log "Cloning dotfiles into $DOTFILES_DIR"
  mkdir -p "$(dirname "$DOTFILES_DIR")"
  git clone --recurse-submodules "$REPO_URL" "$DOTFILES_DIR"
fi

# Install repo git hooks (keeps macos/symbolichotkeys.plist in sync on push).
ln -sf "$DOTFILES_DIR/git-hooks/pre-push" "$DOTFILES_DIR/.git/hooks/pre-push"

# --- 4. Apply the flake -----------------------------------------------------
log "Applying nix-darwin config .#$FLAKE_HOST (asks for sudo)"
if command -v darwin-rebuild >/dev/null 2>&1; then
  sudo darwin-rebuild switch --flake "$DOTFILES_DIR#$FLAKE_HOST"
else
  sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake "$DOTFILES_DIR#$FLAKE_HOST"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

# --- 4b. Keyboard shortcuts (not expressible in nix-darwin) -----------------
HOTKEYS="$DOTFILES_DIR/macos/symbolichotkeys.plist"
if [ -f "$HOTKEYS" ]; then
  log "Restoring keyboard shortcuts from snapshot"
  defaults import com.apple.symbolichotkeys "$HOTKEYS"
fi

# --- 5. Things outside Nix/Homebrew -----------------------------------------
if [ ! -x "$HOME/.cargo/bin/rustup" ]; then
  log "Installing Rust (rustup)"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# rustup is on PATH only in new shells; use it from here on.
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
if command -v rustup >/dev/null 2>&1; then
  log "Rust components and targets"
  try rustup component add rust-analyzer rust-src
  try rustup target add wasm32-unknown-unknown x86_64-unknown-linux-gnu
fi

if [ ! -e "$HOME/.config/nvim" ]; then
  log "Cloning nvim config"
  git clone "$NVIM_URL" "$HOME/.config/nvim"
fi

# Node via nvm (the Homebrew `node` formula has no corepack).
export NVM_DIR="$HOME/.nvm"
if [ -s /opt/homebrew/opt/nvm/nvm.sh ] && [ -z "$(ls -A "$NVM_DIR/versions/node" 2>/dev/null)" ]; then
  log "Installing Node LTS (nvm)"
  mkdir -p "$NVM_DIR"
  # nvm.sh is not written for `set -eu`; run it in a relaxed subshell.
  try bash -c '. /opt/homebrew/opt/nvm/nvm.sh && nvm install --lts && nvm alias default "lts/*"'
fi

if ! command -v claude >/dev/null 2>&1; then
  log "Installing Claude Code"
  try bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
fi

# vm-claude from the submodule; it installs `msb` (microsandbox) on first run.
mkdir -p "$HOME/.local/bin"
ln -sf "$DOTFILES_DIR/claude/vm-claude/vm-claude" "$HOME/.local/bin/vm-claude"

if command -v uv >/dev/null 2>&1 && ! command -v graphify >/dev/null 2>&1; then
  log "Installing graphify"
  try bash -c 'uv tool install graphifyy && "$HOME/.local/bin/graphify" install'
fi

# Marketplace skills (caveman, tdd, ...): not vendored in claude/skills.
if [ ! -e "$HOME/.claude/skills/caveman" ] && command -v npx >/dev/null 2>&1; then
  log "Installing marketplace skills"
  try npx -y skills add mattpocock/skills -g -a claude-code -y
fi

if command -v go >/dev/null 2>&1 && [ ! -x "$HOME/golang/bin/scaffolder" ]; then
  log "Installing scaffolder"
  try env GOPATH="$HOME/golang" go install github.com/Guilospanck/scaffolder@latest
fi

log "Done. What a script cannot do:
  - Mission Control: add desktops until there are 4 (Cmd+1..4 switch to them)
  - Secretive: create a key, add it to GitHub (auth + signing), then re-run
    this script; it writes ~/.gitconfig.local with the signing key
  - Approve the permission prompts (Accessibility for Rectangle, Raycast,
    Clipy; Input Monitoring for KeyCastr) and the default-browser dialog
  - Put secrets and machine-specific settings in ~/.zshrc.local
  - Sign in to apps; restore ~/.claude if wanted (see claude/README.md)
  - Open a new terminal"
