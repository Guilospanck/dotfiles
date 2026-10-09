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
in
{
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

  home.file = claudeSkills // {
    ".zshrc".source = link "zsh/.zshrc";
    ".tmux.conf".source = link "tmux/.tmux.conf";

    ".gitconfig".source = link "git/.gitconfig";
    ".gitignore".source = link "git/.gitignore";
    ".gitallowedsigners".source = link "git/.gitallowedsigners";

    ".claude/CLAUDE.md".source = link "claude/CLAUDE.md";

    ".claude/settings.json".source = link "claude/settings.json";
    ".claude/hooks".source = link "claude/hooks";

    # `docker buildx` / `docker compose` only work as subcommands from here.
    ".docker/cli-plugins/docker-buildx".source =
      config.lib.file.mkOutOfStoreSymlink "/opt/homebrew/opt/docker-buildx/bin/docker-buildx";
    ".docker/cli-plugins/docker-compose".source =
      config.lib.file.mkOutOfStoreSymlink "/opt/homebrew/opt/docker-compose/bin/docker-compose";
  };

  xdg.configFile."ghostty".source = link "ghostty";
  xdg.configFile."starship.toml".source = link "starship/starship.toml";
  xdg.configFile."consult-llm/config.yaml".source = link "consult-llm/config.yaml";
  xdg.configFile."workmux/config.yaml".source = link "workmux/config.yaml";
  xdg.configFile."odin/odinfmt.json".source = link "odin/odinfmt.json";

  # Commit signing uses a Secretive key, which is bound to this Mac's Secure
  # Enclave and so cannot live in the repo. Once the key exists, write the
  # machine-local half of the git config (included from git/.gitconfig).
  home.activation.gitSigning = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    keys="$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/PublicKeys"
    if [ ! -e "$HOME/.gitconfig.local" ]; then
      key=$(ls "$keys"/*.pub 2>/dev/null | head -n 1 || true)
      if [ -n "$key" ]; then
        printf '[user]\n\tsigningkey = %s\n[commit]\n\tgpgsign = true\n[url "git@github.com:"]\n\tinsteadOf = https://github.com/\n' "$key" > "$HOME/.gitconfig.local"
        echo "wrote ~/.gitconfig.local (signing key: $key)"
      else
        echo "no Secretive key yet: create one in Secretive, add it to GitHub, then re-run the switch"
      fi
    fi
  '';

  # Not managed here:
  # - ~/.gitconfig.local: per-machine signing key, written by gitSigning above.
  # - ~/.config/nvim: a clone of kickstart-modular.nvim, done by bootstrap.sh.
  # - the rest of ~/.claude (credentials, history, sessions, …): PII / secrets.
  # - alacritty: replaced by ghostty; alacritty/ kept in the repo to switch back.
  # - zellij: replaced by tmux; zellij/ kept in the repo to switch back.
}
