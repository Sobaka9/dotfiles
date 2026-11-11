return {
    ---- MONITORS ----
    primaryMonitor = "DP-3",
    secondaryMonitor = "DP-2",

    primaryMode = { width = 2560, height = 1440, refresh = 240 },
    secondaryMode = { width = 1920, height = 1080, refresh = 144 },

    ---- MY PROGRAMS ----
    terminal = "alacritty",
    fileManager = "nemo",
    browser = "zen-browser",
    codeEditor = "com.microsoft.VSCode",
    discord = "equibop",

    ---- MISC ----
    mainMod = "SUPER",
    scriptsDir = os.getenv("HOME") .. "/dotfiles/custom-scripts/",
}
