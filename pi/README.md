# Pi config

Portable config from `~/.pi/agent`, linked by home-manager (`nix/home.nix`).

| Target | Source |
| --- | --- |
| `~/.pi/agent/settings.json` | `pi/settings.json` |
| `~/.pi/agent/extensions/<name>` | `pi/extensions/<name>`, one link per tracked entry |

`settings.json` keeps the current model preferences and disables install
telemetry. `extensions/clear.ts` adds `/clear` as an alias for `/new`.

## Apply

Stage new files with `git add pi`, then run `just switch`. Existing files are
backed up as `<target>.hm-bak`. Restart Pi or run `/reload` afterward.
Pi itself must already be installed; this config does not install it.

Edits through these links show up in this repo. To track another extension,
add it under `pi/extensions/`, stage it, and run `just switch`. The agent and
extensions directories remain real directories so machine-local resources can
coexist with the tracked files.

## Privacy

Do not copy the entire agent directory. Credentials (`auth.json`,
`mcp-auth.json`), sessions, trust decisions, model caches, installed packages,
and the Pi installation stay outside the repo. `.gitignore` allows only the
settings, extensions, and this README at the top level of `pi/`.

The imported settings omit `deviceId` and `lastChangelogVersion`. Pi can write
these fields back into the linked settings file; remove them before committing.
The pre-commit guard rejects either field in staged `pi/settings.json`. It also
rejects Pi state outside the portable paths above, even if force-added, and
blocks auth, trust, model-cache, backup, and lock files under `pi/extensions/`.
Review `git diff -- pi` for identifiers, tokens, private endpoints, and absolute
machine paths before every commit. Never put credentials in tracked settings
or extensions; use Pi's local authentication or environment variables instead.
