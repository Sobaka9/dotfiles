-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

local cfg = require("settings")

local primaryMonitor = cfg.primaryMonitor
local secondaryMonitor = cfg.secondaryMonitor
local scriptsDir = cfg.scriptsDir

local function mode(m)
    return string.format("%dx%d@%d", m.width, m.height, m.refresh)
end

-- Primary monitor on the right
hl.monitor({ output = primaryMonitor, mode = mode(cfg.primaryMode), position = "1920x0", scale = "auto", bitdepth = 10 })
-- Secondary monitor on the left
hl.monitor({ output = secondaryMonitor, mode = mode(cfg.secondaryMode), position = "0x180",  scale = "auto" })

---- AUTOSTART ----
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
hl.on("hyprland.start", function()
    hl.exec_cmd("QSG_RENDER_LOOP=threaded qs -c bar")
    hl.exec_cmd("xwaylandvideobridge")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")

    hl.exec_cmd("xrandr --output " .. primaryMonitor .. " --primary")

    -- cliphist
    hl.exec_cmd("wl-paste --type text --watch cliphist store") -- Stores only text data
    hl.exec_cmd("wl-paste --type image --watch cliphist store") -- Stores only image data

    -- Set QuadCast RGB color on launch
    hl.exec_cmd("sudo quadcastrgb solid ffffff")
    -- Input mapping
    hl.exec_cmd("input-remapper-control --command stop-all && input-remapper-control --command autoload")

    -- RAIN PARK : 2600287972 | EVENING SHINJUKU : 2582147561 | SEA OF STARS : 2837310594 | CAT PLANET : 2892621110
    -- WALLPAPER ENGINE : primaryMonitor | secondaryMonitor | --no--fullscreen-pause
    hl.exec_cmd(scriptsDir .. "start-wallpaperengine.sh ~/Backgrounds/2837310594/ ~/Backgrounds/2892621110/ false")
end)

---- ENVIRONMENT VARIABLES ----
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
-- GTK theme is theme-managed via ~/.config/gtk-3.0/settings.ini (see
-- ~/.config/themes/). Do NOT pin GTK_THEME here — an env var hard-overrides
-- settings.ini and would freeze the theme switcher's GTK changes.


---- LOOK AND FEEL ----
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

        sensitivity = -0.4,
        special_fallthrough = true,
    },

    general = {
        gaps_in  = 5,
        gaps_out = 10,

        border_size = 3,
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

        shadow = {
            enabled        = true,
            range          = 30,
            render_power   = 3,
            offset         = { 0, 1 },
            color          = "rgba(00000060)",
            color_inactive = "rgba(00000040)",
        },

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
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        background_color = "rgb(000000)",
        middle_click_paste = false,
        on_focus_under_fullscreen = 1,
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


---- ANIMATIONS ----
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("defaultBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows",    enabled = true, speed = 7,  bezier = "defaultBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7,  bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",     enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle",enabled = true, speed = 8,  bezier = "default" })
hl.animation({ leaf = "fade",       enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6,  bezier = "defaultBezier" })


---- KEYBINDINGS AND RULES ----
-- Kept in their own files; both read shared values from settings.lua.
require("binding")
require("windowrule")
