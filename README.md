# dotfiles

Yet another dotfiles in order to speed the process of updating new work environment.

## How to use

```bash
./install_all.sh
```

## Ubuntu

There's a Ubuntu `dconf` file that can be used to load the configurations to match
the ones we have regarding Alacritty, Zellij and nvim.

To load it, do:

```shell
dconf load / < dconf-backup.ini
```
