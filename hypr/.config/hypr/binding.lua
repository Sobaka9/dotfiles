-- Keybindings. Required from hyprland.lua.
-- See https://wiki.hypr.land/Configuring/Basics/Binds/

local cfg = require("settings")

local mainMod = cfg.mainMod
local scriptsDir = cfg.scriptsDir
local terminal = cfg.terminal
local fileManager = cfg.fileManager
local browser = cfg.browser
local menu = cfg.menu
local discord = cfg.discord

hl.bind(mainMod .. " + Return",     hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C",          hl.dsp.window.close())
hl.bind(mainMod .. " + mouse:274",  hl.dsp.window.close())
hl.bind(mainMod .. " + M",          hl.dsp.exit())
hl.bind(mainMod .. " + E",          hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V",          hl.dsp.exec_cmd(scriptsDir .. "toggle_floating.sh"))
hl.bind(mainMod .. " + SHIFT + H",  hl.dsp.exec_cmd(scriptsDir .. "toggle_hdr.sh"))
hl.bind(mainMod .. " + R",          hl.dsp.global("quickshell:launcher"))
hl.bind(mainMod .. " + SHIFT + T",  hl.dsp.global("quickshell:launcher-themes"))
hl.bind(mainMod .. " + SHIFT + V",  hl.dsp.global("quickshell:launcher-clipboard"))
hl.bind(mainMod .. " + P",          hl.dsp.window.pseudo()) -- dwindle
hl.bind(mainMod .. " + F",          hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + D",          hl.dsp.exec_cmd(discord))
hl.bind(mainMod .. " + B",          hl.dsp.exec_cmd(browser))

hl.bind(mainMod .. " + X", function()
    hl.dispatch(hl.dsp.exec_cmd(discord))
    hl.dispatch(hl.dsp.exec_cmd(scriptsDir .. "start-zen.sh"))
    hl.dispatch(hl.dsp.exec_cmd("steam"))
    hl.dispatch(hl.dsp.exec_cmd(terminal .. " --class startup-term", { workspace = "3 silent" }))
end)

hl.bind(mainMod .. " + G",      hl.dsp.group.toggle())

-- ALT + Tab: cycle to next window and bring it to the top
hl.bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)

-- Move focus with mainMod + arrow keys or hjkl
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. " + H",     hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + L",     hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + K",     hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + J",     hl.dsp.focus({ direction = "d" }))

-- Switch workspaces with mainMod + [0-9] and move active window with mainMod + SHIFT + [0-9]
-- (key 0 maps to workspace 10)
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Maybe disables middle-click paste?
hl.bind("mouse:274", hl.dsp.exec_cmd("wl-copy -pc"), { non_consuming = true })

-- Screenshot Keybinds (requires hyprshot, satty and wl-clipboard)
-- Every capture opens in satty: Enter copies + saves it, Escape discards it.
hl.bind(mainMod .. " + S",         hl.dsp.exec_cmd(scriptsDir .. "screenshot.sh monitor"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(scriptsDir .. "screenshot.sh region"))
hl.bind(mainMod .. " + ALT + S",   hl.dsp.exec_cmd(scriptsDir .. "screenshot.sh window"))

-- Scroll through existing workspaces with mainMod + scroll
-- hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
-- hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace_scroll.sh prev"))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace_scroll.sh next"))

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer --increase 5"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer --decrease 5"))
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("pamixer --toggle-mute"))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
