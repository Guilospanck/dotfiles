-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

-- External to the left of the laptop
-- [ HDMI-A-1 ][ eDP-1 ]
hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "-1920x0", scale = 1 })

-- Configuration of monitors: external on top of the laptop
-- [ HDMI-A-1 ]
-- [  eDP-1   ]
-- hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })
-- hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "0x-1080", scale = 1 })

-- --------------------------------- Workspaces per monitor ---------------------------------
-- Send 1-4 to the external monitor *when it exists*.
-- (Do NOT mark them persistent; they'll only exist if/when HDMI-A-1 is connected.)
-- INFO: the key insight is: rules don't auto-migrate existing workspaces. Hence why in
-- bindings.lua we have a SUPER grave (CMD `) to do the migration correctly.
for workspace = 1, 4 do
  hl.workspace_rule({ workspace = tostring(workspace), monitor = "HDMI-A-1" })
end

-- Keep workspaces 5 and 6 on the laptop panel.
-- Mark them persistent so they always exist on eDP-1.
hl.workspace_rule({ workspace = "5", monitor = "eDP-1", persistent = true })
hl.workspace_rule({ workspace = "6", monitor = "eDP-1", persistent = true })

-- GDK scale is GDK_SCALE, the factor GTK draws its own UI at. Straight 1x setup
-- for low-resolution displays like 1080p or 1440p.
hl.env("GDK_SCALE", "1")
