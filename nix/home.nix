{ config, dotfilesDir, ... }:

let
  # Out-of-store links point at the repo checkout, so edits apply live
  # without a rebuild (same as the old hand-made symlinks).
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
in
{
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

  home.file.".zshrc".source = link "zsh/.zshrc";
  home.file.".tmux.conf".source = link "tmux/.tmux.conf";

  xdg.configFile."ghostty".source = link "ghostty";
  xdg.configFile."alacritty".source = link "alacritty";
  xdg.configFile."zellij".source = link "zellij";

  # Not managed here:
  # - ~/.gitconfig: git/.gitconfig holds placeholders (signing key, PAT).
  # - ~/.config/nvim: a clone of kickstart-modular.nvim, done by bootstrap.sh.
  # - ~/.claude: claude/ is a snapshot, not a live config.
}
