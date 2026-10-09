# dotfiles

Yet another dotfiles in order to speed the process of updating new work environment.

## Branches

We have the `main` branch that is mostly for MacOS and we have the `omarchy` branch that is supposed to be used with `Omarchy` (Arch, Wayland, Hyprland).

## New Mac: one command

```bash
curl -fsSL https://raw.githubusercontent.com/Guilospanck/dotfiles/main/bootstrap.sh | bash
```

`bootstrap.sh` installs the Xcode Command Line Tools and Nix (Determinate Systems
installer), clones this repo with submodules into `~/repos/MyRepositories/dotfiles`,
applies the flake with nix-darwin (trackpad, mouse, keyboard remap and
shortcuts, Dock, Finder, menu bar, power, app preferences, login apps, …), and
installs the git hooks. It is safe to re-run. On an already-cloned repo,
`just setup` does the same.

| Env var | Default | Meaning |
| --- | --- | --- |
| `DOTFILES_DIR` | `~/repos/MyRepositories/dotfiles` | Clone location. The flake links configs from this path, so change `dotfilesDir` in `flake.nix` too. |
| `FLAKE_HOST` | `mac` | `darwinConfigurations` entry to apply (`mac` or `G1459`). |

Before the flake it installs Rosetta. After it, it installs what Homebrew does
not carry: Rust via rustup (plus components and targets), Node LTS via nvm,
Claude Code, graphify, the marketplace Claude skills, and it links `vm-claude`
and clones the nvim config (`kickstart-modular.nvim`) into `~/.config/nvim` if
missing. These extra steps warn and continue if one fails.

What no script can do:

- **Mission Control desktops**: add desktops until there are 4. `Cmd+1..4`
  switch to them, but macOS has no way to create desktops from a script.
- **Secretive key**: it lives in the Secure Enclave, so each Mac needs its own.
  Create it in Secretive, add it to GitHub (authentication and signing) and to
  `git/.gitallowedsigners`, then re-run `just switch`: it writes
  `~/.gitconfig.local` (signing key, `commit.gpgsign`, SSH rewrite for GitHub).
- **Privacy permissions**: Accessibility for Rectangle, Raycast and Clipy,
  Input Monitoring for KeyCastr. Only a click or the company device management
  can grant these.
- **Default browser**: macOS always asks to confirm.
- Secrets in `~/.zshrc.local`, and app sign-ins.

## Day to day

| Command | What it does |
| --- | --- |
| `just setup` | One command on an already-cloned repo: switch + restore shortcuts + install hooks |
| `just switch` | Apply the config: Homebrew packages/apps, macOS defaults, config links |
| `just update` | Bump flake inputs (`flake.lock`), then switch |
| `just push [remote] [args]` | Fold any keyboard-shortcut changes into the same push, then push |
| `just hotkeys-export` | Capture this Mac's keyboard shortcuts into `macos/symbolichotkeys.plist` |
| `just hotkeys-import` | Restore keyboard shortcuts on a new Mac from that snapshot |
| `just install-hooks` | Symlink repo git hooks into `.git/hooks` (once per clone; bootstrap does it too) |

Keyboard shortcuts live in `macos/symbolichotkeys.plist`, which every
`just switch` re-applies; everything else lives in `nix/darwin.nix` (macOS
defaults, Caps Lock as Escape, app preferences, login apps). To keep the shortcut snapshot in
sync, use `just push` — it refreshes and commits the plist (if changed) *before*
pushing, so the update ships in that push. A `pre-push` hook is the safety net
for a raw `git push`: it does the same refresh + commit, but git has already
resolved the refs, so that commit lands on your *next* push. Both are macOS-only
and never block a push.

Nix only sees files tracked by git, so `git add` new files before `just switch`.

### Layout

| Path | What it holds |
| --- | --- |
| `flake.nix` | Entry point; `darwinConfigurations.mac` / `.G1459` |
| `nix/darwin.nix` | System: nix-homebrew, zsh, macOS defaults |
| `nix/homebrew.nix` | Homebrew taps, formulae and casks. Add a package here, then `just switch` |
| `nix/home.nix` | home-manager: config links into this repo |
| `macos/` | macOS state nix-darwin can't express (keyboard-shortcut snapshot) |

`nix/homebrew.nix` uses `cleanup = "none"`, so switching never uninstalls
anything. Once the list is pruned, set it to `"zap"` to make Homebrew fully
declarative.

### Config links

home-manager links these to the repo checkout (out-of-store links, so edits
apply live without a rebuild):

| Target | Source |
| --- | --- |
| `~/.zshrc` | `zsh/.zshrc` |
| `~/.tmux.conf` | `tmux/.tmux.conf` |
| `~/.config/ghostty` | `ghostty/` |
| `~/.gitconfig`, `~/.gitignore`, `~/.gitallowedsigners` | `git/` (same names) |
| `~/.config/starship.toml` | `starship/starship.toml` |
| `~/.config/consult-llm/config.yaml` | `consult-llm/config.yaml` |
| `~/.config/workmux/config.yaml` | `workmux/config.yaml` |
| `~/.config/odin/odinfmt.json` | `odin/odinfmt.json` |
| `~/.docker/cli-plugins/docker-{buildx,compose}` | the Homebrew binaries |
| `~/.claude/CLAUDE.md` | `claude/CLAUDE.md` |
| `~/.claude/settings.json` | `claude/settings.json` |
| `~/.claude/hooks` | `claude/hooks/` |
| `~/.claude/skills/<name>` | `claude/skills/<name>/`, one link per tracked skill |

An existing real file at a target is moved to `<target>.hm-bak` on the first switch.

Alacritty (replaced by ghostty) and Zellij (replaced by tmux) are no longer
installed or linked, but `alacritty/` and `zellij/` stay in the repo. To switch
back, add the `alacritty` cask or `zellij` formula to `nix/homebrew.nix` and the
matching `xdg.configFile."<name>".source = link "<name>";` line to `nix/home.nix`.

> Secrets and machine-specific settings go in `~/.zshrc.local`, which `.zshrc` sources if present. Never commit it.

## Ubuntu

There's a Ubuntu `dconf` file that can be used to load the configurations to match
the ones we have regarding Alacritty, Zellij and nvim.

To load it, do:

```shell
dconf load / < dconf-backup.ini
```
