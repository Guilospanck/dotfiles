# dotfiles

Yet another dotfiles in order to speed the process of updating new work environment.

## Branches

We have the `main` branch that is mostly for MacOS and we have the `omarchy` branch that is supposed to be used with `Omarchy` (Arch, Wayland, Hyprland).

## How to use with Omarchy

When you first install Omarchy, its default files/configs will reside at `~/.local/share/omarchy/default/*`. You usually should not change them (with exception of the `bin` files. See the `/bin` folder README here of this repository).

Then, to actually configure it for yourself, you're gonna do them via the configs at `~/.config/` (`~/.config/fcitx5/`, `~/.config/hypr/`, `~/.config/waybar/` etc). Those configs are the ones that will modify the default ones.

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
