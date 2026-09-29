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
then applies the flake with nix-darwin. It is safe to re-run.

| Env var | Default | Meaning |
| --- | --- | --- |
| `DOTFILES_DIR` | `~/repos/MyRepositories/dotfiles` | Clone location. The flake links configs from this path, so change `dotfilesDir` in `flake.nix` too. |
| `FLAKE_HOST` | `mac` | `darwinConfigurations` entry to apply (`mac` or `G1459`). |

After the flake, it also installs Rust via rustup and clones the nvim config
(`kickstart-modular.nvim`) into `~/.config/nvim` if missing.

Manual steps left: fill in `~/.gitconfig` from `git/.gitconfig` (signing key,
GitHub token), put secrets in `~/.zshrc.local`, sign in to apps.

## Day to day

| Command | What it does |
| --- | --- |
| `just switch` | Apply the config: Homebrew packages/apps, macOS defaults, config links |
| `just update` | Bump flake inputs (`flake.lock`), then switch |

Nix only sees files tracked by git, so `git add` new files before `just switch`.

### Layout

| Path | What it holds |
| --- | --- |
| `flake.nix` | Entry point; `darwinConfigurations.mac` / `.G1459` |
| `nix/darwin.nix` | System: nix-homebrew, zsh, macOS defaults |
| `nix/homebrew.nix` | Homebrew taps, formulae and casks. Add a package here, then `just switch` |
| `nix/home.nix` | home-manager: config links into this repo |

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
| `~/.config/zellij` | `zellij/` |

An existing real file at a target is moved to `<target>.hm-bak` on the first switch.

Alacritty is no longer installed or linked (ghostty replaced it), but `alacritty/`
stays in the repo. To switch back, add the `alacritty` cask to `nix/homebrew.nix`
and `xdg.configFile."alacritty".source = link "alacritty";` to `nix/home.nix`.

> Secrets and machine-specific settings go in `~/.zshrc.local`, which `.zshrc` sources if present. Never commit it.

## Ubuntu

There's a Ubuntu `dconf` file that can be used to load the configurations to match
the ones we have regarding Alacritty, Zellij and nvim.

To load it, do:

```shell
dconf load / < dconf-backup.ini
```
