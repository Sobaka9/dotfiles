-- Workspace, layer and window rules. Required from hyprland.lua.
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

local cfg = require("settings")

local primaryMonitor   = cfg.primaryMonitor
local secondaryMonitor = cfg.secondaryMonitor
local fileManager      = cfg.fileManager
local codeEditor       = cfg.codeEditor
local discord          = cfg.discord

local function scaled(mode, factor)
    return { math.floor(mode.width * factor), math.floor(mode.height * factor) }
end

local startupTermSize = scaled(cfg.secondaryMode, 0.75)

local sattyMode = cfg.primaryMode
if cfg.secondaryMode.width * cfg.secondaryMode.height < sattyMode.width * sattyMode.height then
    sattyMode = cfg.secondaryMode
end
local sattySize = scaled(sattyMode, 0.8)

-- Bind workspaces to monitors
-- See https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
hl.workspace_rule({ workspace = "1", monitor = secondaryMonitor })
hl.workspace_rule({ workspace = "2", monitor = secondaryMonitor })
hl.workspace_rule({ workspace = "3", monitor = secondaryMonitor })
hl.workspace_rule({ workspace = "4", monitor = secondaryMonitor })

hl.workspace_rule({ workspace = "5", monitor = primaryMonitor })
hl.workspace_rule({ workspace = "6", monitor = primaryMonitor })
hl.workspace_rule({ workspace = "7", monitor = primaryMonitor })
hl.workspace_rule({ workspace = "8", monitor = primaryMonitor })
hl.workspace_rule({ workspace = "9", monitor = primaryMonitor })

-- Layer rules
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
hl.layer_rule({
    name  = "layerrule-1",
    match = { namespace = "logout_dialog" },
    blur  = true,
})

hl.layer_rule({
    name = "quickshell-no-anim",
    match = { namespace = "quickshell" },
    no_anim = true,
})

-- Stack the quickshell bar beneath the panels that hang off it (popouts,
-- launcher, notifications), so its drop shadow doesn't fall across their
-- tops. Within a layer a higher `order` is drawn first, and this still holds
-- while quickshell lifts the bar to the overlay layer for the launcher.
hl.layer_rule({
    name    = "quickshell-bar",
    match   = { namespace = "quickshell-bar" },
    no_anim = true,
    order   = 1,
})

-- Window rules. Order matters: rules are evaluated top to bottom.
-- Rules for screen sharing
hl.window_rule({
    name    = "windowrule-1",
    match   = { class = "^(xwaylandvideobridge)$" },
    opacity = "0.0 override 0.0 override",
    no_anim = true,
    no_initial_focus = true,
    max_size = { 1, 1 },
    no_blur = true,
})

hl.window_rule({
    name      = "windowrule-2",
    match     = { class = discord },
    workspace = "1 silent",
    opacity   = "0.9",
})

hl.window_rule({
    name      = "windowrule-3",
    match     = { class = "^(" .. codeEditor .. "|jetbrains-idea)$" },
    workspace = "6",
})

hl.window_rule({
    name      = "Steam",
    match     = { class = "steam" },
    workspace = "7 silent",
})

hl.window_rule({
    name     = "fix-steam-float",
    match    = { initial_title = "Steam", float = true },
    float    = false,
    maximize = true,
})

hl.window_rule({
    name      = "windowrule-5",
    match     = { class = "com.stremio.stremio" },
    workspace = "8",
})

hl.window_rule({
    name    = "windowrule-6",
    match   = { class = fileManager },
    opacity = "1",
})

hl.window_rule({
    name   = "satty",
    match  = { class = "^(com.gabm.satty)$" },
    float  = true,
    center = true,
    size   = sattySize,
})

hl.window_rule({
    name   = "startup-term",
    match  = { class = "^(startup-term)$" },
    float  = true,
    center = true,
    size   = startupTermSize,
})

hl.window_rule({
    name             = "jetbrains",
    match            = { class = "jetbrains-idea", title = "^win(.*)" },
    workspace        = "6",
    no_initial_focus = true,
    float            = true,
})

hl.window_rule({
    name      = "npc editor",
    match     = { class = "npc-visual-editor" },
    workspace = "8",
})

hl.window_rule({
    name = "flstudio",
    match = { class = "fl64.exe" },
    workspace = "8",
})
