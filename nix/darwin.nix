{ user, ... }:

{
  imports = [ ./homebrew.nix ];

  # Nix itself is installed and managed by the Determinate Systems installer.
  nix.enable = false;

  system.primaryUser = user;
  users.users.${user}.home = "/Users/${user}";

  programs.zsh.enable = true;

  # Let Nix own the Homebrew install; adopt an existing one on this machine.
  nix-homebrew = {
    enable = true;
    inherit user;
    autoMigrate = true;
  };

  system.defaults = {
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
    };
    finder.AppleShowAllExtensions = true;
    dock.autohide = true;
  };

  system.stateVersion = 6;
}
