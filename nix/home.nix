{ config, lib, dotfilesDir, ... }:

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
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

  home.file = claudeSkills // piExtensions // {
    ".zshrc".source = link "zsh/.zshrc";
    ".tmux.conf".source = link "tmux/.tmux.conf";

    ".gitconfig".source = link "git/.gitconfig";
    ".gitignore".source = link "git/.gitignore";
    ".gitallowedsigners".source = link "git/.gitallowedsigners";

    ".claude/CLAUDE.md".source = link "claude/CLAUDE.md";

    ".claude/settings.json".source = link "claude/settings.json";
    ".claude/hooks".source = link "claude/hooks";

    ".pi/agent/settings.json".source = link "pi/settings.json";

    # `docker buildx` / `docker compose` only work as subcommands from here.
    ".docker/cli-plugins/docker-buildx".source =
      config.lib.file.mkOutOfStoreSymlink "/opt/homebrew/opt/docker-buildx/bin/docker-buildx";
    ".docker/cli-plugins/docker-compose".source =
      config.lib.file.mkOutOfStoreSymlink "/opt/homebrew/opt/docker-compose/bin/docker-compose";
  };

  # Link only portable config; gateway credentials/state stay machine-local.
  # gateway.env holds non-secret runtime env only; the pre-commit scan covers it.
  xdg.configFile."openshell/.justfile".source = link "openshell/.justfile";
  # gateway.toml is copied, not linked: the gateway refuses a symlinked config.
  xdg.configFile."openshell/gateway.env".source = link "openshell/gateway.env";
  xdg.configFile."openshell/osh".source = link "openshell/osh";
  xdg.configFile."openshell/gateway-docker.toml".source = link "openshell/gateway-docker.toml";
  xdg.configFile."openshell/gateway-docker-service".source = link "openshell/gateway-docker-service";
  # providers/images link to the standalone oh-my-openshell checkout (sibling of
  # this repo), not the submodule clone, so edits land where they get committed.
  xdg.configFile."openshell/providers".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/../oh-my-openshell/providers";
  xdg.configFile."openshell/images".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/../oh-my-openshell/images";

  xdg.configFile."ghostty".source = link "ghostty";
  xdg.configFile."starship.toml".source = link "starship/starship.toml";
  xdg.configFile."consult-llm/config.yaml".source = link "consult-llm/config.yaml";
  xdg.configFile."workmux/config.yaml".source = link "workmux/config.yaml";
  xdg.configFile."odin/odinfmt.json".source = link "odin/odinfmt.json";

  home.activation.openshellGatewayConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dest="''${XDG_CONFIG_HOME:-$HOME/.config}/openshell"
    mkdir -p "$dest"
    rm -f "$dest/gateway.toml"
    install -m 644 "${dotfilesDir}/openshell/gateway.toml" "$dest/gateway.toml"
  '';

  # Upstream distributes microsandbox through its installer, outside Homebrew.
  # Activation has a minimal PATH; expose curl and the tools used by the installer.
  home.activation.microsandbox = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH" \
      /bin/bash "${dotfilesDir}/claude/install-microsandbox.sh"; then
      echo "warning: microsandbox installation failed; retry with just install-microsandbox" >&2
    fi
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

  # Not managed here:
  # - ~/.gitconfig.local: per-machine signing key, written by gitSigning above.
  # - ~/.config/nvim: a clone of kickstart-modular.nvim, done by bootstrap.sh.
  # - the rest of ~/.claude (credentials, history, sessions, …): PII / secrets.
  # - the rest of ~/.pi/agent (auth, sessions, trust, install, …): local state.
  # - alacritty: replaced by ghostty; alacritty/ kept in the repo to switch back.
  # - zellij: replaced by tmux; zellij/ kept in the repo to switch back.
}
