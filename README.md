# dotfiles

Yet another dotfiles in order to speed the process of updating new work environment.

## Branches

We have the `main` branch that is mostly for MacOS and we have the `omarchy` branch that is supposed to be used with `Omarchy` (Arch, Wayland, Hyprland).

## How to use

```bash
./install_all.sh
```

## Symlink setup (for agents)

To set up the dotfiles, create symbolic links from this repository to the expected config locations. The following commands assume the repository is cloned at `$DOTFILES_DIR`.

```bash
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Alacritty
ln -sfn "$DOTFILES_DIR/alacritty" ~/.config/alacritty

# Zellij
ln -sfn "$DOTFILES_DIR/zellij" ~/.config/zellij

# Ghostty
ln -sfn "$DOTFILES_DIR/ghostty" ~/.config/ghostty

# Tmux
ln -sf "$DOTFILES_DIR/tmux/.tmux.conf" ~/.tmux.conf
```

> **Note:** Alacritty, Zellij, and Ghostty symlink the entire directory. Tmux symlinks the single `.tmux.conf` file to `~/.tmux.conf`.

## Ubuntu

There's a Ubuntu `dconf` file that can be used to load the configurations to match
the ones we have regarding Alacritty, Zellij and nvim.

To load it, do:

```shell
dconf load / < dconf-backup.ini
```
