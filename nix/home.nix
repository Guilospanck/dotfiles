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

    ".claude/settings.json".source = link "claude/settings.json";
    ".claude/hooks".source = link "claude/hooks";
  };

  xdg.configFile."ghostty".source = link "ghostty";

  # Not managed here:
  # - ~/.gitconfig: git/.gitconfig holds placeholders (signing key, PAT).
  # - ~/.config/nvim: a clone of kickstart-modular.nvim, done by bootstrap.sh.
  # - the rest of ~/.claude (credentials, history, sessions, …): PII / secrets.
  # - alacritty: replaced by ghostty; alacritty/ kept in the repo to switch back.
  # - zellij: replaced by tmux; zellij/ kept in the repo to switch back.
}
