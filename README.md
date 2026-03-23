# dotfiles

Yet another dotfiles in order to speed the process of updating new work environment.

## Branches

We have the `main` branch that is mostly for MacOS and we have the `omarchy` branch that is supposed to be used with `Omarchy` (Arch, Wayland, Hyprland).

## How to use with Omarchy

When you first install Omarchy, its default files/configs will reside at `~/.local/share/omarchy/default/*`. You usually should not change them (with exception of the `bin` files. See the `/bin` folder README here of this repository).

Then, to actually configure it for yourself, you're gonna do them via the configs at `~/.config/` (`~/.config/fcitx5/`, `~/.config/hypr/`, `~/.config/waybar/` etc). Those configs are the ones that will modify the default ones.

## Setup after a fresh Omarchy install

Clone this repo and switch to the `omarchy` branch:

```bash
cd ~
git clone <repo-url> dotfiles
cd dotfiles
git checkout omarchy
```

### Symlinks

Remove the existing Omarchy defaults first, then symlink. Each command replaces `~/.config/<dir>` with a symlink to this repo:

```bash
DOTFILES_DIR=~/dotfiles

# Ghostty (terminal) — uses omarchy dynamic theme + font
rm -rf ~/.config/ghostty
ln -sfn "$DOTFILES_DIR/ghostty" ~/.config/ghostty

# Tmux (multiplexer) — launched automatically by ghostty
rm -rf ~/.config/tmux
ln -sfn "$DOTFILES_DIR/tmux" ~/.config/tmux

# Hyprland (window manager)
rm -rf ~/.config/hypr
ln -sfn "$DOTFILES_DIR/hypr" ~/.config/hypr

# Waybar (status bar)
rm -rf ~/.config/waybar
ln -sfn "$DOTFILES_DIR/waybar" ~/.config/waybar

# Fcitx5 (input method)
rm -rf ~/.config/fcitx5
ln -sfn "$DOTFILES_DIR/fcitx5" ~/.config/fcitx5
```

### Zsh prompt

Add the prompt to `~/.zshrc` (after Omarchy's default sourcing):

```bash
# Prompt: shortened path + %
PROMPT='%F{blue}%~%f %# '
```

### How it works

- **Ghostty** auto-launches tmux on startup and sends Unicode PUA characters for keybindings (Super+E for split, Super+N for new tab, etc.)
- **Tmux** receives those PUA characters and maps them to actions (split-window, new-window, kill-pane, etc.)
- **Theme** follows Omarchy automatically — Ghostty loads colors from `~/.config/omarchy/current/theme/ghostty.conf`, and tmux uses terminal color names (`blue`, `brightblack`) which resolve to the active theme palette
- **Font** is managed by `omarchy-font-set` which updates the `font-family` line in the Ghostty config via sed
