# dotfiles

Yet another dotfiles in order to speed the process of updating new work environment.

## Branches

We have the `main` branch that is mostly for MacOS and we have the `omarchy` branch that is supposed to be used with `Omarchy` (Arch, Wayland, Hyprland).

## New Omarchy machine: one command

```bash
curl -fsSL https://raw.githubusercontent.com/Guilospanck/dotfiles/omarchy/bootstrap.sh | bash
```

`bootstrap.sh` installs Nix (Determinate Systems installer), clones this repo
with submodules into `~/dotfiles`, installs `yay`, applies the flake with
home-manager (config links — see below — and user-level CLI packages), and
installs the git hooks. It is safe to re-run. On an already-cloned repo,
`just setup` applies the config and installs hooks and `bin/` patches (the
other extra installers below are bootstrap-only).

| Env var | Default | Meaning |
| --- | --- | --- |
| `DOTFILES_DIR` | `~/dotfiles` | Clone location. The flake links configs from this path, so change `dotfilesDir` in `flake.nix` too. |
| `DOTFILES_HOST` | by arch | Flake config to apply (auto: `omarchy-arm` on aarch64, else `omarchy`): `omarchy` (x86_64, user `guilospanck`) or `omarchy-arm` (aarch64, user `gman`). Also read by `just switch`. |

After the flake it installs what Nix/pacman do not carry: Rust via rustup
(plus components and targets), Claude Code, `scaffolder`, and GUI apps via
`yay` (Postman, Notion — see "Layout" below for where to add more).

What no script can do:

- **SSH key**: the private key stays out of the repo, so each machine needs
  its own. Create `~/.ssh/id_ed25519` with `ssh-keygen -t ed25519`, add it to
  GitHub (authentication and signing) and to `git/.gitallowedsigners`, then
  re-run `just switch`: it writes `~/.gitconfig.local` (signing key,
  `commit.gpgsign`, SSH rewrite for GitHub).
- **OpenShell gateway**: run `osh setup` once to install the systemd service
  and container runtime (the config itself is already linked by home-manager).
- Secrets in `~/.zshrc.local`, and app sign-ins.

## Day to day

| Command | What it does |
| --- | --- |
| `just setup` | Switch + install hooks + apply `bin/` patches |
| `just switch` | Apply the config: packages, config links |
| `just update` | Bump flake inputs (`flake.lock`), then switch |
| `just install-hooks` | Enable tracked pre-commit + pre-push hooks (once per clone; bootstrap does it too) |
| `just apply-bin` | Copy `bin/omarchy-*` patches into `~/.local/share/omarchy/bin/` (re-run after `omarchy update`) |

Nix only sees files tracked by git, so `git add` new files before `just switch`.

### Commit privacy guard

`just install-hooks` sets this clone's `core.hooksPath` to `.githooks`.
Before every commit, Gitleaks scans the **entire staged snapshot** (not unstaged
edits or untracked files), blocking detected secrets, literal credential
assignments, emails, US SSNs, and labeled phone numbers. Output is redacted.
Missing Gitleaks or scanner errors also block commits; it is installed by
`just switch` via `nix/home.nix`.

Put shell secrets in `~/.zshrc.local`, which `.zshrc` already sources. Local
`.zshrc.local`, `.gitconfig.local`, and `.env*` files are ignored and the hook
rejects them even if force-added. The hook also rejects Pi runtime fields
(`deviceId`, `lastChangelogVersion`) in staged `pi/settings.json` and private Pi
state files; see [`pi/README.md`](pi/README.md). After moving a secret, re-stage
the cleaned tracked file. The hook also preserves executable bits.

Rules live in `.gitleaks.toml`; the repository's existing public email identity,
example-domain emails, and GNOME extension IDs are
explicit exceptions. Review any new exceptions carefully—never allowlist a real
credential. You can run `git-hooks/check-secrets` manually after staging files.

This is a heuristic safety net, not proof that a file contains no PII: it cannot
reliably identify arbitrary names, addresses, or every secret format. Submodule
contents/history are not scanned; install guards in those repositories too.
Local Git hooks can be bypassed (e.g. `--no-verify`), so do not bypass this one.

### Layout

| Path | What it holds |
| --- | --- |
| `flake.nix` | Entry point; `homeConfigurations.omarchy` |
| `nix/home.nix` | home-manager: config links into this repo, user-level CLI packages |

System-level packages (Hyprland/Wayland, fcitx5 engines, fonts) stay on
Omarchy/pacman, not Nix. GUI apps that have no `pacman`/AUR equivalent go in
`bootstrap.sh`'s `yay -S` line.

### Config links

home-manager links these to the repo checkout (out-of-store links, so edits
apply live without a rebuild):

| Target | Source |
| --- | --- |
| `~/.zshrc` | `zsh/.zshrc` |
| `~/.config/ghostty` | `ghostty/` |
| `~/.config/tmux` | `tmux/` |
| `~/.config/hypr` | `hypr/` |
| `~/.config/waybar` | `waybar/` |
| `~/.config/fcitx5` | `fcitx5/` |
| `~/.config/nvim` | `nvim/` (git submodule) |
| `~/.config/openshell/{.justfile,osh,providers,images}` | `openshell/` (same names; git submodule, [oh-my-openshell](https://github.com/Guilospanck/oh-my-openshell)) |
| `~/.config/openshell/gateway.toml` | copy of `openshell/gateway-linux.toml`, written on switch (the gateway rejects symlinked configs; rerun `just switch` and restart the gateway after editing) |
| `~/.gitconfig`, `~/.gitignore`, `~/.gitallowedsigners` | `git/` (same names) |
| `~/.config/starship.toml` | `starship/starship.toml` |
| `~/.config/workmux/config.yaml` | `workmux/config.yaml` |
| `~/.config/odin/odinfmt.json` | `odin/odinfmt.json` |
| `~/.claude/CLAUDE.md` | `claude/CLAUDE.md` |
| `~/.claude/settings.json` | `claude/settings.json` |
| `~/.claude/hooks` | `claude/hooks/` |
| `~/.claude/skills/<name>` | `claude/skills/<name>/`, one link per tracked skill |
| `~/.pi/agent/settings.json` | `pi/settings.json` |
| `~/.pi/agent/extensions/<name>` | `pi/extensions/<name>`, one link per tracked extension |

See [`pi/README.md`](pi/README.md) for Pi setup and privacy notes. Pi credentials,
sessions, and other machine-local state are not linked or tracked.

An existing real file or directory at a target is moved to `<target>.bak` on the first switch.

Alacritty (replaced by ghostty) and Zellij (replaced by tmux) are no longer
installed or linked, but `alacritty/` and `zellij/` stay in the repo to switch
back if needed.

> Secrets and machine-specific settings go in `~/.zshrc.local`, which `.zshrc` sources if present. Never commit it.

### How it works

- **Ghostty** auto-launches tmux on startup and sends Unicode PUA characters for keybindings (Super+E for split, Super+N for new tab, etc.)
- **Tmux** receives those PUA characters and maps them to actions (split-window, new-window, kill-pane, etc.)
- **Theme** follows Omarchy automatically — Ghostty loads colors from `~/.config/omarchy/current/theme/ghostty.conf`, and tmux uses terminal color names (`blue`, `brightblack`) which resolve to the active theme palette
- **Font** is managed by `omarchy-font-set` which updates the `font-family` line in the Ghostty config via sed

## Ubuntu

There's a Ubuntu `dconf` file that can be used to load the configurations to match
the ones we have regarding Alacritty, Zellij and nvim.

To load it, do:

```shell
dconf load / < dconf-backup.ini
```
