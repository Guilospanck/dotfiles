{ user, config, lib, ... }:

let
  # Run a command as the login user from the (root) activation script, the
  # same way nix-darwin applies `system.defaults`.
  asUser = cmd: ''launchctl asuser "$(id -u -- ${user})" sudo --user=${user} -- ${cmd}'';

  # Apps started at login. `open -g` launches in the background and is a no-op
  # when the app is already running or not installed.
  loginApps = [ "Rectangle" "Raycast" "Clipy" "AI Usage Bar" "Notion" ];
  loginAgents = lib.listToAttrs (map (app: {
    name = "login-${lib.toLower (lib.replaceStrings [ " " ] [ "-" ] app)}";
    value.serviceConfig = {
      ProgramArguments = [ "/usr/bin/open" "-g" "-a" app ];
      RunAtLoad = true;
    };
  }) loginApps);
in
{
  imports = [ ./homebrew.nix ];

  # Nix itself is installed and managed by the Determinate Systems installer.
  nix.enable = false;

  system.primaryUser = user;
  users.users.${user}.home = "/Users/${user}";

  programs.zsh.enable = true;

  # Put Homebrew on PATH for every login shell, including non-interactive ones
  # that never read ~/.zshrc (ghostty starts tmux via `zsh --login -c`). Also
  # sets HOMEBREW_PREFIX, which zsh/.zshrc relies on.
  programs.zsh.loginShellInit = ''
    eval "$(${config.homebrew.prefix}/bin/brew shellenv)"
  '';

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
      "com.apple.trackpad.enableSecondaryClick" = true; # two-finger tap = right click
    };

    # Trackpad (writes both AppleMultitouchTrackpad + Bluetooth domains)
    trackpad = {
      Clicking = true; # tap to click
      Dragging = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = false;
    };

    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "Nlsv"; # list view
      ShowPathbar = true;
      ShowHardDrivesOnDesktop = true;
      ShowExternalHardDrivesOnDesktop = false;
      FXRemoveOldTrashItems = true; # empty Trash after 30 days
    };

    dock = {
      autohide = true;
      tilesize = 57;
      minimize-to-application = true;
      show-recents = false;
      # Keep desktops in a fixed order so Cmd+1..4 always hit the same one.
      mru-spaces = false;
      persistent-apps = [ "/Applications/Ghostty.app" ];
      persistent-others = [ ];
    };

    spaces.spans-displays = false;

    # Native window tiling off; Rectangle does it.
    WindowManager = {
      EnableTilingByEdgeDrag = false;
      EnableTopTilingByEdgeDrag = false;
      EnableTilingOptionAccelerator = false;
      EnableTiledWindowMargins = false;
    };

    menuExtraClock.ShowSeconds = true;
    controlcenter.Bluetooth = true; # show in menu bar

    # Escape hatch: domains/keys with no typed option.
    # Values captured verbatim from this machine's `defaults read`.
    CustomUserPreferences = {
      # Mouse pointer + scroll-wheel speed (NSGlobalDomain string keys)
      NSGlobalDomain = {
        "com.apple.mouse.scaling" = 3.0;
        "com.apple.scrollwheel.scaling" = 1.7;
        NSAutomaticPeriodSubstitutionEnabled = true;
        ContextMenuGesture = 1; # secondary click enabled
        AppleLanguages = [ "en-PT" "pt-PT" ];
        AppleLocale = "en_PT";
        # App menu shortcuts: Ctrl+= / Ctrl+- in every app
        NSUserKeyEquivalents = {
          "Zoom In" = "^=";
          "Zoom Out" = "^-";
        };
      };
      "com.google.Chrome".NSUserKeyEquivalents = {
        "Zoom In" = "^=";
        "Zoom Out" = "^-";
      };
      "com.apple.finder" = {
        FXPreferredGroupBy = "Name";
        FXArrangeGroupViewBy = "Name";
      };
      # Bluetooth mouse gestures/buttons
      "com.apple.driver.AppleBluetoothMultitouch.mouse" = {
        MouseButtonMode = "OneButton";
        MouseHorizontalScroll = 1;
        MouseMomentumScroll = 1;
        MouseVerticalScroll = 1;
        MouseOneFingerDoubleTapGesture = 0; # smart zoom off
        MouseTwoFingerDoubleTapGesture = 3;
        MouseTwoFingerHorizSwipeGesture = 2;
      };
      "com.apple.AppleMultitouchMouse".MouseOneFingerDoubleTapGesture = 0;

      # --- Third-party apps (installed by nix/homebrew.nix) ---
      # keyCode + modifierFlags: 1048576 = Cmd, 1179648 = Shift+Cmd, 786432 = Ctrl+Opt
      "com.knollsoft.Rectangle" = {
        launchOnLogin = true;
        SUEnableAutomaticChecks = false;
        larger = { keyCode = 24; modifierFlags = 1048576; }; # Cmd+=
        smaller = { keyCode = 27; modifierFlags = 1048576; }; # Cmd+-
        nextDisplay = { keyCode = 19; modifierFlags = 1179648; }; # Shift+Cmd+2
        previousDisplay = { keyCode = 18; modifierFlags = 1179648; }; # Shift+Cmd+1
        reflowTodo = { keyCode = 45; modifierFlags = 786432; };
        toggleTodo = { keyCode = 11; modifierFlags = 786432; };
      };
      # Cmd+Space; Spotlight's own shortcut is disabled in symbolichotkeys.plist.
      "com.raycast.macos".raycastGlobalHotkey = "Command-49";
      "com.clipy-app.Clipy" = {
        loginItem = true;
        kCPYCollectCrashReport = false;
        kCPYPrefShowAlertBeforeClearHistoryKey = false;
      };
      "io.github.keycastr" = {
        "default.allKeys" = true;
        "default.allModifiedKeys" = false;
        "default.commandKeysOnly" = false;
        "default.fontSize" = 18.34;
        "default.fadeDelay" = 0.851;
        "default.fadeDuration" = 0.132;
        "default.keystrokeDelay" = 1;
        "mouse.displayOption" = 0;
        selectedVisualizer = "Default";
        SUEnableAutomaticChecks = false;
        SUAutomaticallyUpdate = false;
      };
      "com.bearisdriving.BGM.App" = {
        AutoPauseMusicEnabled = false;
        StatusBarIcon = 0;
      };
      "com.guilospanck.aiusagebar" = {
        titleMetric = "scoped:Spend";
        "titleMetric.Claude" = "fiveHour";
        "titleMetric.OpenAI" = "scoped:Spend";
      };
    };
  };

  system.startup.chime = false;

  # Caps Lock acts as Escape, on every keyboard.
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };

  launchd.user.agents = loginAgents // {
    # nix-darwin only applies the key mapping at switch time and hidutil
    # forgets it on reboot, so set it again at every login.
    key-mapping.serviceConfig = {
      ProgramArguments = [
        "/usr/bin/hidutil"
        "property"
        "--set"
        (builtins.toJSON { UserKeyMapping = config.system.keyboard.userKeyMapping; })
      ];
      RunAtLoad = true;
    };
  };

  # Settings system.defaults cannot express: the per-host (ByHost) global
  # domain, keyboard shortcuts, and power. Then reload preferences so they
  # apply without a logout. Nothing here may fail the switch.
  system.activationScripts.postActivation.text = ''
    echo "applying per-host defaults, keyboard shortcuts and power settings..." >&2
    ${asUser "defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true"} || true
    ${asUser "defaults -currentHost write NSGlobalDomain com.apple.trackpad.twoFingerDoubleTapGesture -int 1"} || true
    ${asUser "defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 2"} || true

    # Keyboard shortcuts (Cmd+1..4 switch desktop, Spotlight off, ...).
    # Snapshot kept current by `just push` / `just hotkeys-export`.
    ${asUser "defaults import com.apple.symbolichotkeys ${../macos/symbolichotkeys.plist}"} || true

    # Battery: display off after 20 min. Power adapter: never sleep.
    pmset -b displaysleep 20 sleep 1 >/dev/null 2>&1 || true
    pmset -c displaysleep 10 sleep 0 >/dev/null 2>&1 || true

    # nix-homebrew leaves share/zsh/site-functions/_brew pointing at a
    # $PREFIX/completions tree that only exists inside brew's store path, so the
    # symlink dangles and zsh's compinit warns on every shell. Repoint it at the
    # real completion through the stable Library/Homebrew symlink (which
    # nix-homebrew updates to the current brew), so it survives version bumps.
    brewcomp="${config.homebrew.prefix}/Library/Homebrew/../../completions/zsh/_brew"
    if [ -e "$brewcomp" ]; then
      ln -sf "$brewcomp" "${config.homebrew.prefix}/share/zsh/site-functions/_brew"
    fi

    ${asUser "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u"} || true
    killall -qu ${user} Finder ControlCenter WindowManager || true
  '';

  system.stateVersion = 6;
}
