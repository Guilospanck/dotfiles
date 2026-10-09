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

[ "$(uname -s)" = Darwin ] || die "macOS only (use the omarchy branch on Arch)"

# --- 1. Xcode Command Line Tools (git, compilers) ---------------------------
if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Xcode Command Line Tools (accept the dialog)"
  xcode-select --install || true
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
else
  log "Xcode Command Line Tools already installed"
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

if [ ! -e "$HOME/.config/nvim" ]; then
  log "Cloning nvim config"
  git clone "$NVIM_URL" "$HOME/.config/nvim"
fi

log "Done. Manual steps left:
  - Fill in ~/.gitconfig from git/.gitconfig (signing key, GitHub token)
  - Put secrets and machine-specific settings in ~/.zshrc.local
  - Sign in to apps; restore ~/.claude if wanted (see claude/README.md)
  - Open a new terminal"
