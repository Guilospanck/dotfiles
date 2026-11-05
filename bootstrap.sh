#!/usr/bin/env bash
# bootstrap.sh - set up Omarchy (Arch, Wayland, Hyprland) from zero: Nix,
# this repo, yay, then home-manager via the flake.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Guilospanck/dotfiles/omarchy/bootstrap.sh | bash
#
# Env:
#   DOTFILES_DIR  where to clone the repo (default ~/dotfiles; the flake
#                 links configs from this path, so keep them in sync)
#
# Safe to re-run: every step checks before acting.

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
REPO_URL="https://github.com/Guilospanck/dotfiles.git"

log() { printf '\n==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
warn() { printf 'warning: %s\n' "$*" >&2; }
# Run an optional step; report a failure but keep going.
try() { "$@" || warn "failed (skipped): $*"; }

command -v pacman >/dev/null 2>&1 || die "Arch/Omarchy only (use the main branch on macOS)"

# --- 1. Nix -----------------------------------------------------------------
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

# --- 2. This repo -----------------------------------------------------------
if [ -d "$DOTFILES_DIR/.git" ]; then
  log "Updating $DOTFILES_DIR"
  git -C "$DOTFILES_DIR" pull --ff-only
  git -C "$DOTFILES_DIR" submodule update --init --recursive
else
  log "Cloning dotfiles into $DOTFILES_DIR"
  mkdir -p "$(dirname "$DOTFILES_DIR")"
  git clone --recurse-submodules --branch omarchy "$REPO_URL" "$DOTFILES_DIR"
fi

# --- 3. yay (AUR helper) -----------------------------------------------------
if ! command -v yay >/dev/null 2>&1; then
  log "Installing yay"
  sudo pacman -S --needed --noconfirm base-devel git
  tmp="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
  (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$tmp"
else
  log "yay already installed"
fi

# --- 4. Apply the flake ------------------------------------------------------
log "Applying home-manager config .#omarchy"
nix run home-manager/master -- switch --flake "$DOTFILES_DIR#omarchy" -b bak

# --- 5. Git hooks -------------------------------------------------------------
log "Installing git hooks"
sh "$DOTFILES_DIR/.githooks/install.sh"

# --- 6. bin/ patches ----------------------------------------------------------
log "Applying bin/ patches"
try just --justfile "$DOTFILES_DIR/.justfile" apply-bin

# --- 7. Things outside Nix/pacman --------------------------------------------
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

if ! command -v claude >/dev/null 2>&1; then
  log "Installing Claude Code"
  try bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
fi

if command -v go >/dev/null 2>&1 && [ ! -x "$HOME/golang/bin/scaffolder" ]; then
  log "Installing scaffolder"
  try env GOPATH="$HOME/golang" go install github.com/Guilospanck/scaffolder@latest
fi

# --- 8. GUI apps (AUR) --------------------------------------------------------
log "Installing GUI apps via yay"
try yay -S --needed --noconfirm postman-bin notion-app-electron

log "Done. What a script cannot do:
  - SSH key: ssh-keygen -t ed25519, add it to GitHub (auth + signing), re-run
    this script; home-manager writes ~/.gitconfig.local with the signing key
  - OpenShell gateway: run 'osh setup' once to install the systemd service and
    container runtime for the OpenShell gateway (config is already linked)
  - Approve any polkit/sudo prompts yay needs for GUI app installs
  - Sign in to apps; put secrets and machine-specific settings in ~/.zshrc.local
  - Open a new terminal"
