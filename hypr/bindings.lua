-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.
--
-- See current bindings and descriptions:
--   omarchy menu keybindings --print
--
-- INFO: the defaults live in /usr/share/omarchy/default/hypr/

local browser = "omarchy-launch-browser"
-- Upstream renamed `omarchy-lock-screen` to `omarchy-system-lock`; keepassxc is
-- locked inline here, matching the approach in hypridle.conf.
local lock_screen = "omarchy-system-lock; pgrep -x keepassxc >/dev/null && keepassxc --lock"
local terminal = "uwsm app -- $TERMINAL"

-- Hyprland's send_shortcut can leave synthetic key state stuck or repeating, so
-- drive the down/up edges explicitly. Same workaround Omarchy's own clipboard
-- bindings use: https://github.com/hyprwm/Hyprland/discussions/14099
local function send_shortcut_once(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))

    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

--------------------------------------------------------------------------- UNBINDINGS

-- We use these inside nvim
hl.unbind("SUPER + P")
hl.unbind("SUPER + K")
hl.unbind("SUPER + J")
hl.unbind("SUPER + Y")
hl.unbind("ALT + TAB")

hl.unbind("SUPER + W")
hl.unbind("SUPER + T")
hl.unbind("SUPER + A")
hl.unbind("SUPER + R")
hl.unbind("SUPER + F")
hl.unbind("SUPER + C")
hl.unbind("SUPER + V")
hl.unbind("SUPER + L")
hl.unbind("SUPER + SHIFT + T")
hl.unbind("SUPER + SHIFT + M") -- Harpoon
hl.unbind("SUPER + SHIFT + E") -- Harpoon
hl.unbind("SUPER + SHIFT + N") -- Harpoon
hl.unbind("SUPER + SHIFT + P") -- Harpoon

-- Resize nvim windows: omarchy binds these to movefocus in
-- default/hypr/bindings/tiling.lua, which would grab them before Ghostty
hl.unbind("SUPER + LEFT")
hl.unbind("SUPER + RIGHT")
hl.unbind("SUPER + UP")
hl.unbind("SUPER + DOWN")

-- Omarchy 4 claims these for the scratchpad, "full width" and the group/browser
-- bindings; reclaim them for the application bindings below.
hl.unbind("SUPER + grave")
hl.unbind("SUPER + SHIFT + grave")
hl.unbind("SUPER + ALT + F")
hl.unbind("SUPER + SHIFT + B")
hl.unbind("SUPER + SHIFT + G")

-- Omarchy 4 added these three defaults after your config was written; each
-- collided with a binding below, and Hyprland fires BOTH on press.
hl.unbind("SUPER + SHIFT + RETURN") -- was: Browser
hl.unbind("SUPER + CTRL + Q")       -- was: Calculator (omacalc)
hl.unbind("SUPER + ALT + RETURN")   -- was: Tmux (attaches a persistent "Work" session)

--------------------------------------------------------------------------- BINDINGS

o.bind("SUPER + ALT + RETURN", "Tmux", 'uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)" tmux new')
o.bind("SUPER + SHIFT + RETURN", "Terminal", terminal .. ' --dir="$(omarchy-cmd-terminal-cwd)"')
o.bind("SUPER + SHIFT + B", "Browser", browser)
-- o.bind("SUPER + SHIFT + M", "Music", { focus = "spotify", launch = "spotify" })
o.bind("SUPER + SHIFT + grave", "Passwords", o.launch("keepassxc"))
o.bind("SUPER + CTRL + SHIFT + 3", "Screenshot of window", "omarchy-capture-screenshot windows")
o.bind("SUPER + CTRL + SHIFT + 4", "Screenshot of region", "omarchy-capture-screenshot region")
o.bind("SUPER + ALT + F", "Force full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
o.bind("SUPER + grave", "Move workspaces to monitor", os.getenv("HOME") .. "/.config/hypr/scripts/move-workspaces-to-monitor.sh")
o.bind("SUPER + CTRL + Q", "Lock Screen", lock_screen)

-- o.bind("SUPER + F", "File manager", o.launch("nautilus --new-window"))
-- o.bind("SUPER + SHIFT + B", "Browser (private)", browser .. " --private")
-- o.bind("SUPER + N", "Editor", "omarchy-launch-editor")
-- o.bind("SUPER + T", "Activity", { tui = "btop" })
-- o.bind("SUPER + D", "Docker", { tui = "lazydocker" })
-- o.bind("SUPER + G", "Signal", { focus = "signal", launch = "signal-desktop" })
-- o.bind("SUPER + O", "Obsidian", { focus = "obsidian", launch = "obsidian" })

o.bind("SUPER + SHIFT + equal", "ChatGPT", { webapp = "https://chatgpt.com" })
o.bind("SUPER + SHIFT + G", "GitHub", { webapp = "https://github.com/guilospanck" })
-- o.bind("SUPER + SHIFT + A", "Grok", { webapp = "https://grok.com" })
-- o.bind("SUPER + C", "Calendar", { webapp = "https://app.hey.com/calendar/weeks/" })
-- o.bind("SUPER + E", "Email", { webapp = "https://app.hey.com" })
-- o.bind("SUPER + Y", "YouTube", { focus = true, webapp = "https://youtube.com/" })
-- o.bind("SUPER + SHIFT + G", "WhatsApp", { focus = true, webapp = "https://web.whatsapp.com/" })
-- o.bind("SUPER + ALT + G", "Google Messages", { focus = true, webapp = "https://messages.google.com/web/conversations" })
-- o.bind("SUPER + X", "X", { webapp = "https://x.com/" })
-- o.bind("SUPER + SHIFT + X", "X Post", { webapp = "https://x.com/compose/post" })

--------------------------------------------------------------------------- OVERWRITES

o.bind("SUPER + SHIFT + K", "Show key bindings", "omarchy-menu-keybindings")
o.bind("SUPER + SHIFT + J", "Toggle split", hl.dsp.layout("togglesplit")) -- dwindle

-- Close KeePassXC with a hard kill, and rebind SUPER+W -> CTRL+W elsewhere.
--
-- This was two separate SUPER+W binds shelling out to bash+jq+hyprctl, relying
-- on Hyprland firing both and each guarding itself with a class check. Under the
-- Lua config `hyprctl dispatch sendshortcut "CTRL,W,activewindow"` no longer
-- parses, so that half failed silently on every press. Done natively now: one
-- bind, one class lookup, no subprocesses.
--
-- W is conditional: Ghostty needs the raw SUPER+W (it maps it to the PUA char
-- tmux binds to kill-pane). Sending CTRL+W too would leak ^W into the pane --
-- harmless in zsh, but in nvim ^W is the window prefix and swallows the PUA char.
o.bind("SUPER + W", "Close window", function()
  local window = hl.get_active_window()
  local class = window and (window.class or window.initial_class) or ""

  if class == "org.keepassxc.KeePassXC" then
    hl.exec_cmd("pkill keepassxc")
  elseif class == "com.mitchellh.ghostty" then
    send_shortcut_once("SUPER", "W")()
  else
    send_shortcut_once("CTRL", "W")()
  end
end)

-- Rebind SUPER -> Ctrl
o.bind("SUPER + T", nil, send_shortcut_once("CTRL", "T"))
o.bind("SUPER + A", nil, send_shortcut_once("CTRL", "A"))
o.bind("SUPER + R", nil, send_shortcut_once("CTRL", "R"))
o.bind("SUPER + F", nil, send_shortcut_once("CTRL", "F"))
o.bind("SUPER + L", nil, send_shortcut_once("CTRL", "L"))
o.bind("SUPER + SHIFT + T", nil, send_shortcut_once("CTRL + SHIFT", "T"))

-- Omarchy 4 ships terminal-aware universal copy/paste/cut on SUPER+C/V/X
-- (default/hypr/bindings/clipboard.lua): CTRL+C / CTRL+V normally, CTRL+Insert /
-- SHIFT+Insert in terminals. These two lines keep your previous fixed mapping
-- instead. Delete them (and the SUPER+C / SUPER+V unbinds above) to use
-- Omarchy's version, which also handles the terminal case for copy.
o.bind("SUPER + C", nil, send_shortcut_once("CTRL", "C"))
o.bind("SUPER + V", nil, send_shortcut_once("CTRL + SHIFT", "V"))
