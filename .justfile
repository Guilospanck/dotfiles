# dotfiles tasks -- run `just` (or `just --list`) to see recipes.

# list available recipes
default:
    @just --list

# apply the home-manager config (packages, apps, config links)
switch:
    nix run home-manager/master -- switch --flake "{{justfile_directory()}}#omarchy" -b bak

# bump flake inputs (nixpkgs, home-manager), then apply
update:
    nix flake update --flake "{{justfile_directory()}}"
    just switch

# enable tracked pre-commit and pre-push hooks (run once per clone)
install-hooks:
    sh "{{justfile_directory()}}/.githooks/install.sh"

# copy bin/omarchy-* patches into Omarchy's own bin dir (re-run after `omarchy update`)
apply-bin:
    install -d "{{env_var('HOME')}}/.local/share/omarchy/bin"
    install -m 755 "{{justfile_directory()}}/bin/omarchy-lock-screen" "{{env_var('HOME')}}/.local/share/omarchy/bin/omarchy-lock-screen"
    install -m 755 "{{justfile_directory()}}/bin/omarchy-theme-set" "{{env_var('HOME')}}/.local/share/omarchy/bin/omarchy-theme-set"
    @echo "applied bin/ patches -> ~/.local/share/omarchy/bin/"

# one command to set up this machine: config + git hooks + bin patches
setup: switch install-hooks apply-bin
