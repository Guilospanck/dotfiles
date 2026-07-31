Here are files from Omarchy configuration that would lie at `~/.local/share/omarchy/bin/`.

I just added the files that I changed from the default configuration from Omarchy and also only added the changes themselves, not the whole file.

When reinstalling Omarchy, after it's done via the normal way, just add the changes to those files.

## Obsolete

- `omarchy-lock-screen` — as of the 2026-07-31 Omarchy update this script is no
  longer the lock entry point; `omarchy-system-lock` replaced it. The KeePassXC
  locking it provided now lives in `../hypr/hypridle.conf`, which is tracked
  here and therefore survives `omarchy update`. Kept only for reference.

Prefer putting customizations in `~/.config/` (tracked in this repo) over
patching Omarchy's `bin/`, since anything under `~/.local/share/omarchy/` is
overwritten on update.
