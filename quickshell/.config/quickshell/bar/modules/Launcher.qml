// Application launcher: its modes, search and results.
//
// It is shown as one of the popout panels (popouts/LauncherPanel.qml, one per
// monitor), so it shares their surface: moving from the bar's centre to the
// clock reshapes the launcher into the clock panel and back, the way the
// other panels morph into each other. This file holds the state the panels
// display — the search text and the selected row included — and everything
// that acts on it.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "root:/"

Scope {
    id: root

    readonly property bool open: Panels.hasCurrent && Panels.currentName === "launcher"

    // Width of the launcher's surface; the bar's hover zone is the same.
    readonly property int panelWidth: 760

    // "apps" by default; ">" switches to the command list, and picking a
    // command switches to that command's own list.
    property string mode: "apps"
    property string searchText: ""
    property int currentIndex: 0

    // Asks the panels to scroll their lists back to the top.
    signal viewReset()

    // What the empty search field offers to search.
    readonly property string placeholder: {
        switch (root.mode) {
        case "themes":    return "Search themes";
        case "clipboard": return "Search clipboard";
        case "emoji":     return "Search emoji";
        case "commands":  return "Search commands";
        default:          return "Search applications";
        }
    }

    // Text after the ">" in command mode, or the plain query otherwise.
    readonly property string query: {
        const t = root.searchText;
        if (root.mode === "commands")
            return t.startsWith(">") ? t.slice(1).trim() : t.trim();
        return t.trim();
    }

    // Typing ">" at the start switches to the command list; clearing it
    // again drops back to applications.
    onSearchTextChanged: {
        if (root.mode === "apps" && root.searchText.startsWith(">"))
            root.mode = "commands";
        else if (root.mode === "commands" && !root.searchText.startsWith(">"))
            root.mode = "apps";
    }

    // Point the list at `mode`, empty and scrolled to the top. Assigning
    // values that are already set triggers nothing, so this costs nothing
    // when the launcher is already in that state.
    function reset(mode) {
        root.mode = mode;
        root.searchText = "";
        root.currentIndex = 0;
        root.viewReset();
    }

    // Each opening starts fresh, but the list is put back to its default
    // state a moment after the launcher closes or morphs into another panel,
    // not as it goes: rebuilding the list blocks the GUI thread for up to
    // ~100ms, which would stall that transition.
    onOpenChanged: {
        if (root.open)
            resetTimer.stop();
        else
            resetTimer.restart();
    }
    Timer {
        id: resetTimer
        interval: 600
        onTriggered: if (!root.open) root.reset("apps")
    }

    // The popout container spans its monitor's width; the launcher hangs
    // from the middle of the bar.
    function centreOf(screen) {
        return screen ? screen.width / 2 : 0;
    }

    // Open on `mode`, on `screen` (default: the focused monitor); an open
    // launcher only switches lists. The list is prepared first, so a rebuild,
    // when one is needed, lands before the panel starts moving.
    //
    // From the keyboard it opens at once and pinned: it stays until closed,
    // whatever the pointer does. From hovering the bar it opens like any
    // popout — through Panels.open, so it morphs out of a panel already
    // showing — and closes again when the pointer leaves, until something is
    // typed into it (see LauncherPanel).
    function show(mode, screen, fromHover) {
        root.reset(mode);
        if (mode !== "apps")
            LauncherSources.load(mode);
        if (root.open) {
            if (!fromHover)
                Panels.pinned = true;
            return;
        }
        const s = screen || root.focusedScreen();
        if (fromHover) {
            Panels.open("launcher", root.centreOf(s), s);
        } else {
            Panels.apply("launcher", root.centreOf(s), s);
            Panels.pinned = true;
        }
    }

    function close() {
        if (root.open)
            Panels.close();
    }

    // ---- Hover to open ----
    // The middle of the bar, where the window title sits, opens the launcher
    // on that monitor after a short dwell, so sweeping the pointer across the
    // bar doesn't grab the keyboard. Closing on leave is the popouts' own
    // hover handling (Panels).
    property bool titleHovered: false
    property var hoverScreen: null

    function setTitleHovered(on, screen) {
        if (on)
            root.hoverScreen = screen;
        root.titleHovered = on;
        Panels.setHovered("launcher", on);
        if (on) {
            dwellTimer.restart();
        } else {
            dwellTimer.stop();
            Panels.cancelPending("launcher");
        }
    }

    Timer {
        id: dwellTimer
        interval: 150
        onTriggered: {
            if (root.titleHovered && !root.open)
                root.show("apps", root.hoverScreen, true);
        }
    }

    // Hyprland binds to this by name: `hl.dsp.global("quickshell:launcher")`.
    GlobalShortcut {
        appid: "quickshell"
        name: "launcher"
        description: "Toggle the application launcher"
        onPressed: {
            if (root.open)
                root.close();
            else
                root.show("apps", null, false);
        }
    }

    function openIn(mode) {
        if (root.open && root.mode === mode) {
            root.close();
            return;
        }
        root.show(mode, null, false);
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "launcher-themes"
        description: "Open the launcher on the theme list"
        onPressed: root.openIn("themes")
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "launcher-clipboard"
        description: "Open the launcher on clipboard history"
        onPressed: root.openIn("clipboard")
    }

    function focusedScreen() {
        const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        for (let i = 0; i < Quickshell.screens.length; i++)
            if (Quickshell.screens[i].name === name)
                return Quickshell.screens[i];
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    readonly property var entries: {
        const q = root.query;

        if (root.mode === "commands")
            return LauncherSources.commands
                .filter(c => q.length === 0
                          || c.title.toLowerCase().includes(q.toLowerCase())
                          || c.id.includes(q.toLowerCase()))
                .map(c => ({ kind: "command", key: c.id, title: c.title,
                             subtitle: c.subtitle, icon: c.icon, mode: c.mode }));

        if (root.mode !== "apps") {
            const src = root.mode === "clipboard" ? LauncherSources.clipboard
                      : root.mode === "themes" ? LauncherSources.themes
                      : LauncherSources.emoji;
            if (q.length === 0) return src;
            const lq = q.toLowerCase();
            return src.filter(i => i.title.toLowerCase().includes(lq)
                                || (i.subtitle || "").toLowerCase().includes(lq));
        }
        const all = DesktopEntries.applications.values.filter(a => !a.noDisplay);
        const asRow = a => ({ kind: "app", key: a.id, title: a.name || "",
                              subtitle: a.comment || a.genericName || "",
                              icon: a.icon, entry: a });

        if (q.length === 0) {
            return all.slice().sort((a, b) => {
                const d = LauncherUsage.countFor(b.id) - LauncherUsage.countFor(a.id);
                return d !== 0 ? d : (a.name || "").localeCompare(b.name || "");
            }).map(asRow);
        }

        const scored = [];
        for (const a of all) {
            const sc = LauncherSearch.score(a, q);
            if (sc >= 0) scored.push({ entry: a, score: sc });
        }
        scored.sort((x, y) => {
            if (y.score !== x.score) return y.score - x.score;
            const d = LauncherUsage.countFor(y.entry.id) - LauncherUsage.countFor(x.entry.id);
            return d !== 0 ? d : (x.entry.name || "").localeCompare(y.entry.name || "");
        });
        return scored.map(x => asRow(x.entry));
    }

    function launch(row) {
        if (!row) return;

        if (row.kind === "command") {
            root.mode = row.mode;
            LauncherSources.load(row.mode);
            root.searchText = "";
            root.currentIndex = 0;
            return;
        }

        if (row.kind === "app") {
            LauncherUsage.record(row.key);
            row.entry.execute();
        } else {
            LauncherSources.activate(row);
        }
        root.close();
    }

    // Escape backs out one level at a time, closing only once there is
    // nothing left to back out of.
    function back() {
        if (root.mode === "apps") {
            root.close();
        } else if (root.mode === "commands") {
            root.mode = "apps";
            root.searchText = "";
        } else {
            root.mode = "commands";
            root.searchText = ">";
        }
    }
}
