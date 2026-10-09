# dotfiles tasks -- run `just` (or `just --list`) to see recipes.

# where host scripts are installed; override with BINDIR=/some/dir just ...
bindir := env_var_or_default('BINDIR', join(env_var('HOME'), '.local/bin'))

# list available recipes
default:
    @just --list

# install (copy) vm-claude into {{bindir}}; re-run after editing the script
install-vm-claude:
    install -d "{{bindir}}"
    install -m 755 "{{justfile_directory()}}/claude/vm-claude/vm-claude" "{{bindir}}/vm-claude"
    @echo "installed vm-claude -> {{bindir}}/vm-claude"

# symlink vm-claude into {{bindir}} so it tracks repo edits live (no re-copy)
link-vm-claude:
    install -d "{{bindir}}"
    ln -sf "{{justfile_directory()}}/claude/vm-claude/vm-claude" "{{bindir}}/vm-claude"
    @echo "linked vm-claude -> {{bindir}}/vm-claude"

# one command to set up this Mac: config + keyboard shortcuts + git hooks
setup host="mac": (switch host) hotkeys-import install-hooks

# apply the nix-darwin + home-manager config (packages, apps, config links)
switch host="mac":
    sudo darwin-rebuild switch --flake "{{justfile_directory()}}#{{host}}"

# bump flake inputs (nixpkgs, nix-darwin, home-manager), then apply
update host="mac":
    nix flake update --flake "{{justfile_directory()}}"
    just switch {{host}}

# push, folding any macOS keyboard-shortcut changes into the SAME push
push remote="origin" *args:
    "{{justfile_directory()}}/git-hooks/sync-hotkeys"
    git -C "{{justfile_directory()}}" push {{remote}} {{args}}

# symlink repo git hooks into .git/hooks (run once per clone)
install-hooks:
    ln -sf "{{justfile_directory()}}/git-hooks/pre-push" "{{justfile_directory()}}/.git/hooks/pre-push"
    @echo "linked pre-push hook"

# capture this Mac's keyboard shortcuts into the repo (run after changing them)
hotkeys-export:
    defaults export com.apple.symbolichotkeys "{{justfile_directory()}}/macos/symbolichotkeys.plist"
    plutil -convert xml1 "{{justfile_directory()}}/macos/symbolichotkeys.plist"
    @echo "exported -> macos/symbolichotkeys.plist (git add + commit it)"

# restore keyboard shortcuts on a new Mac from the repo snapshot
hotkeys-import:
    defaults import com.apple.symbolichotkeys "{{justfile_directory()}}/macos/symbolichotkeys.plist"
    @echo "imported. log out/in (or `killall cfprefsd`) for it to take effect"
