#!/usr/bin/env bash
# Install the microsandbox CLI required by vm-claude; safe to re-run.
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

if command -v msb >/dev/null 2>&1; then
  printf 'microsandbox (msb) already installed\n'
  exit 0
fi

printf 'Installing microsandbox (msb)\n'
curl -fsSL https://install.microsandbox.dev | sh

if ! command -v msb >/dev/null 2>&1; then
  printf 'error: msb not found after installation; add its install directory to PATH\n' >&2
  exit 1
fi
