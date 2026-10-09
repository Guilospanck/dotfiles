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
      AppleInterfaceStyle = "Dark";
      "com.apple.swipescrolldirection" = true; # natural scroll
      "com.apple.trackpad.forceClick" = true;
      "com.apple.trackpad.scaling" = 1.5; # trackpad tracking speed
      "com.apple.mouse.tapBehavior" = 1; # tap to click
    };

    # Trackpad (writes both AppleMultitouchTrackpad + Bluetooth domains)
    trackpad = {
      Clicking = true; # tap to click
      Dragging = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = false;
    };

    finder.AppleShowAllExtensions = true;
    dock.autohide = true;

    # Escape hatch: domains/keys with no typed option.
    # Values captured verbatim from this machine's `defaults read`.
    CustomUserPreferences = {
      # Mouse pointer + scroll-wheel speed (NSGlobalDomain string keys)
      NSGlobalDomain = {
        "com.apple.mouse.scaling" = 3.0;
        "com.apple.scrollwheel.scaling" = 1.7;
        NSAutomaticPeriodSubstitutionEnabled = true;
      };
      # Bluetooth mouse gestures/buttons
      "com.apple.driver.AppleBluetoothMultitouch.mouse" = {
        MouseButtonMode = "OneButton";
        MouseHorizontalScroll = 1;
        MouseMomentumScroll = 1;
        MouseVerticalScroll = 1;
        MouseTwoFingerDoubleTapGesture = 3;
        MouseTwoFingerHorizSwipeGesture = 2;
      };
    };
  };

  # Modifier-key remaps (caps lock etc). Currently all stock -> leave default.
  # system.keyboard = {
  #   enableKeyMapping = true;
  #   remapCapsLockToControl = true;
  # };

  system.stateVersion = 6;
}
