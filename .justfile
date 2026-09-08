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
