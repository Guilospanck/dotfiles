-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- NVIDIA environment variables (only on machines with the NVIDIA driver loaded).
--
-- Set explicitly rather than relying on default/hypr/nvidia.lua. At the v4.0.0
-- tag that file gates every hl.env() call on o.shell_succeeds(), which wraps
-- os.execute(); inside Hyprland's own Lua state os.execute() can't reap its
-- child and always reports failure, so the vars are silently never set.
-- See https://github.com/basecamp/omarchy/issues/7755 -- upstream master has
-- since reworked shell_succeeds() to use io.popen. These assignments are
-- harmless once that fix lands (same values nvidia.lua picks for a GSP card),
-- so they can be dropped after confirming `systemctl --user show-environment`
-- reports all three.
--
-- Detection uses io.open (no child process) on the driver's procfs entry, which
-- exists only when the proprietary nvidia kernel module is loaded.
local function has_nvidia()
  local f = io.open("/proc/driver/nvidia/version", "r")
  if f then
    f:close()
    return true
  end
  return false
end

if has_nvidia() then
  hl.env("NVD_BACKEND", "direct")
  hl.env("LIBVA_DRIVER_NAME", "nvidia")
  hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
end
