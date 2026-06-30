--------------------
---- MONITORS ------
--------------------
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- NOTE: Your monitor names (DP-1, etc.) might be different.
-- Run 'hyprctl monitors' in a terminal to find the correct names and update them below.

local primaryMonitor = "DP-3"
local secondaryMonitor = "DP-2"

-- Primary monitor on the right
hl.monitor({ output = primaryMonitor,   mode = "2560x1440@240", position = "1920x0", scale = "auto", bitdepth = 10 })
-- Secondary monitor on the left
hl.monitor({ output = secondaryMonitor, mode = "1920x1080@144", position = "0x180",  scale = "auto" })

---------------------
---- MY PROGRAMS ----
---------------------
-- Set programs that you use
local terminal = "alacritty"
local fileManager = "nemo"
local browser = "firefox"
local menu = "wofi --show drun"
local codeEditor = "code"
local discord = "discord"

-------------------
---- AUTOSTART ----
-------------------
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("swww-daemon")
    hl.exec_cmd("sleep 1 & swww img ~/Pictures/wallpapers/thunderstorm-sea.png")
    hl.exec_cmd("xwaylandvideobridge")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")

    hl.exec_cmd("xrandr --output " .. primaryMonitor .. " --primary")

    -- cliphist
    hl.exec_cmd("wl-paste --type text --watch cliphist store") -- Stores only text data
    hl.exec_cmd("wl-paste --type image --watch cliphist store") -- Stores only image data

    -- Notification daemon
    hl.exec_cmd("mako")
    -- Set QuadCast RGB color on launch
    hl.exec_cmd("sudo quadcastrgb solid ffffff")
    -- Input mapping
    hl.exec_cmd("input-remapper-control --command stop-all && input-remapper-control --command autoload")

    -- RAIN PARK : 2600287972 | EVENING SHINJUKU : 2582147561 | SEA OF STARS : 2837310594 | CAT PLANET : 2892621110
    -- WALLPAPER ENGINE : primaryMonitor | secondaryMonitor | --no--fullscreen-pause
    hl.exec_cmd("~/Scripts/start-wallpaperengine.sh ~/backgrounds/2837310594/ ~/backgrounds/2892621110/ false")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
-- NOTE: The following NVIDIA lines can be removed if you use AMD or Intel.
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

-- ---
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "64")
hl.env("GTK_THEME", "Tokyonight-Purple-Dark-Compact-Moon")

-----------------------
---- LOOK AND FEEL ----
-----------------------
-- For all categories, see https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "intl",
        follow_mouse = 1, -- 2 means focus on mouse click

        touchpad = {
            natural_scroll = false,
        },

        tablet = {
            output = primaryMonitor,
            active_area_size = { 100, 70 },
        },

        sensitivity = -0.4, -- -1.0 - 1.0, 0 means no modification.
        special_fallthrough = true,
    },

    general = {
        gaps_in  = 5,
        gaps_out = 10,

        border_size = 2,
        col = {
            active_border = { colors = { "rgba(7b2cbfee)", "rgba(5a189aee)" }, angle = 45 },
            inactive_border = "rgba(262626ee)",
        },

        layout = "dwindle",

        allow_tearing = false,
        hover_icon_on_border = true,
    },

    cursor = {
        no_warps = true,
    },

    decoration = {
        rounding = 10,

        blur = {
            enabled = true,
            size    = 3,
            passes  = 6,
        },
    },

    animations = {
        enabled = true,
    },

    misc = {
        force_default_wallpaper = -1,
        middle_click_paste = false,
        on_focus_under_fullscreen = 1, -- was a bool in hyprlang; now int: 0 ignore, 1 take over, 2 unfullscreen
    },

    debug = {
        disable_logs = false,
    },
})

-- Layout-specific options
-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
    dwindle = {
        preserve_split = true, -- you probably want this
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
    master = {
        mfact = 0.5,
    },
})

--------------------
---- ANIMATIONS ----
--------------------
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("defaultBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows",    enabled = true, speed = 7,  bezier = "defaultBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7,  bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",     enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle",enabled = true, speed = 8,  bezier = "default" })
hl.animation({ leaf = "fade",       enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6,  bezier = "defaultBezier" })

---------------------
---- KEYBINDINGS ----
---------------------
-- See https://wiki.hypr.land/Configuring/Basics/Binds/ for more
local mainMod = "SUPER"

hl.bind(mainMod .. " + Return",     hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C",          hl.dsp.window.close())
hl.bind(mainMod .. " + mouse:274",  hl.dsp.window.close())
hl.bind(mainMod .. " + M",          hl.dsp.exit()) -- consider hyprshutdown / 'uwsm stop' if you use uwsm
hl.bind(mainMod .. " + E",          hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V",          hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_floating.sh"))
hl.bind(mainMod .. " + SHIFT + H",  hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_hdr.sh"))
hl.bind(mainMod .. " + R",          hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P",          hl.dsp.window.pseudo()) -- dwindle
hl.bind(mainMod .. " + F",          hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + D",          hl.dsp.exec_cmd(discord))
hl.bind(mainMod .. " + B",          hl.dsp.exec_cmd(browser))

-- SUPER + X launches several things at once (was four separate `bind` lines on the same key)
hl.bind(mainMod .. " + X", function()
    hl.dispatch(hl.dsp.exec_cmd(discord))
    hl.dispatch(hl.dsp.exec_cmd(browser,  { workspace = "2 silent" }))
    hl.dispatch(hl.dsp.exec_cmd("steam"))
    hl.dispatch(hl.dsp.exec_cmd(terminal, { workspace = "3 silent" }))
end)

hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("wofi-emoji"))
hl.bind(mainMod .. " + G",      hl.dsp.group.toggle())

-- ALT + Tab: cycle to next window and bring it to the top (was two `bind` lines on the same key)
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

-- Maybe disables middle-click paste? (was `bindn`, i.e. non-consuming)
hl.bind("mouse:274", hl.dsp.exec_cmd("wl-copy -pc"), { non_consuming = true })

-- Screenshot Keybinds (requires grim, slurp, and jq)
-- Screenshot active monitor and copy to clipboard
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd([[bash -c 'FILEPATH="${HOME}/Pictures/screenshots/SS-$(date +%Y-%m-%d_%H-%M-%S).png"; grim -o "$(hyprctl monitors -j | jq -r ".[] | select(.focused) | .name")" "$FILEPATH" && cat "$FILEPATH" | wl-copy']]))
-- Screenshot a selected region and copy to clipboard
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd([[bash -c 'FILEPATH="${HOME}/Pictures/screenshots/SS-$(date +%Y-%m-%d_%H-%M-%S).png"; grim -g "$(slurp -w 0)" "$FILEPATH" && cat "$FILEPATH" | wl-copy']]))

-- cliphist with wofi
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd([[cliphist list | wofi --dmenu --pre-display-cmd "echo '%s' | cut -f 2" | cliphist decode | wl-copy]]))

-- Scroll through existing workspaces with mainMod + scroll
-- hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
-- hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace_scroll.sh next"))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace_scroll.sh prev"))

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer --increase 5"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer --decrease 5"))
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("pamixer --toggle-mute"))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------
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
    name             = "jetbrains",
    match            = { class = "jetbrains-idea", title = "^win(.*)" },
    workspace        = "6",
    no_initial_focus = true,
    float            = true,
})