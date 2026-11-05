{ config, lib, pkgs, dotfilesDir, ... }:

let
  # Out-of-store links point at the repo checkout, so edits apply live
  # without a rebuild (same as the old hand-made symlinks).
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";

  # ~/.claude/skills stays a real directory: it also holds marketplace skills
  # (relative symlinks into ~/.agents) and machine-managed ones that must not
  # land in the repo. So link each tracked skill individually.
  claudeSkills = lib.mapAttrs' (name: _:
    lib.nameValuePair ".claude/skills/${name}" { source = link "claude/skills/${name}"; }
  ) (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../claude/skills));

  # Keep untracked / package-managed extensions local to each machine.
  piExtensions = lib.mapAttrs' (name: _:
    lib.nameValuePair ".pi/agent/extensions/${name}" { source = link "pi/extensions/${name}"; }
  ) (builtins.readDir ../pi/extensions);
in
{
  home.username = "guilospanck";
  home.homeDirectory = "/home/guilospanck";
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

  home.file = claudeSkills // piExtensions // {
    ".zshrc".source = link "zsh/.zshrc";

    ".gitconfig".source = link "git/.gitconfig";
    ".gitignore".source = link "git/.gitignore";
    ".gitallowedsigners".source = link "git/.gitallowedsigners";

    ".claude/CLAUDE.md".source = link "claude/CLAUDE.md";
    ".claude/settings.json".source = link "claude/settings.json";
    ".claude/hooks".source = link "claude/hooks";

    ".pi/agent/settings.json".source = link "pi/settings.json";
  };

  # Hyprland/Waybar/Fcitx5/Ghostty/Tmux configs — previously manual `ln -sfn`
  # steps in the README; home-manager owns them now.
  xdg.configFile = {
    "ghostty".source = link "ghostty";
    "tmux".source = link "tmux";
    "hypr".source = link "hypr";
    "waybar".source = link "waybar";
    "fcitx5".source = link "fcitx5";

    "starship.toml".source = link "starship/starship.toml";
    "workmux/config.yaml".source = link "workmux/config.yaml";
    "odin/odinfmt.json".source = link "odin/odinfmt.json";

    # Portable OpenShell config (see openshell/README.md); active_gateway and
    # gateways/ stay machine-local.
    "openshell/.justfile".source = link "openshell/.justfile";
    "openshell/gateway.env".source = link "openshell/gateway.env";
    "openshell/osh".source = link "openshell/osh";
    "openshell/providers".source = link "openshell/providers";
    "openshell/images".source = link "openshell/images";
  };

  # gateway.toml is copied, not linked: the gateway refuses a symlinked
  # config. gateway-linux.toml (not gateway.toml, which is macOS's vm driver,
  # or gateway-docker.toml, macOS's Colima-specific second gateway) is the
  # Docker-driver config OpenShell ships for native Linux.
  home.activation.openshellGatewayConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dest="''${XDG_CONFIG_HOME:-$HOME/.config}/openshell"
    mkdir -p "$dest"
    rm -f "$dest/gateway.toml"
    install -m 644 "${dotfilesDir}/openshell/gateway-linux.toml" "$dest/gateway.toml"
  '';

  # Commit signing uses ~/.ssh/id_ed25519, a private key that cannot live in
  # the repo. Once the key exists, write the machine-local half of the git
  # config (included from git/.gitconfig).
  home.activation.gitSigning = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    key="$HOME/.ssh/id_ed25519.pub"
    if [ ! -e "$HOME/.gitconfig.local" ]; then
      if [ -e "$key" ]; then
        printf '[user]\n\tsigningkey = %s\n[commit]\n\tgpgsign = true\n[url "git@github.com:"]\n\tinsteadOf = https://github.com/\n' "$key" > "$HOME/.gitconfig.local"
        echo "wrote ~/.gitconfig.local (signing key: $key)"
      else
        echo "no ~/.ssh/id_ed25519 yet: run ssh-keygen -t ed25519, add it to GitHub, then re-run the switch"
      fi
    fi
  '';

  # The Linux-nixpkgs equivalents of main's Homebrew formulae. Omarchy/pacman
  # own the Hyprland/Wayland stack, fcitx5 engines, fonts and GUI apps (see
  # bootstrap.sh); these are user-level CLI tools only.
  home.packages = with pkgs; [
    ripgrep
    fd
    fzf
    bat
    eza
    zoxide
    jq
    tree
    tldr
    glow
    shellcheck
    gitleaks
    just
    starship
    go
    gopls
    golangci-lint
    nodejs_22
    kubectl
    kubernetes-helm
    docker-buildx
    docker-compose
    uv
  ];

  # Not managed here:
  # - rustup: installed by bootstrap.sh; `rustup component add` needs the
  #   real rustup, not nixpkgs rustc.
  # - ~/.gitconfig.local: per-machine signing key, written by gitSigning above.
  # - ~/.config/nvim: a git submodule clone (nvim/), see bootstrap.sh.
  # - the rest of ~/.claude (credentials, history, sessions, …): PII / secrets.
  # - the rest of ~/.pi/agent (auth, sessions, trust, install, …): local state.
  # - openshell/gateway*: machine-local gateway state and credentials.
  # - vm-claude / microsandbox: not wired up on omarchy yet.
  # - alacritty: replaced by ghostty; alacritty/ kept in the repo to switch back.
  # - zellij: replaced by tmux; zellij/ kept in the repo to switch back.
}
