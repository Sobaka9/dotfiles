// The things the launcher can list besides applications, and what selecting
// one of them does. Each source replaces a wofi invocation that used to be on
// its own keybind.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")

    // ---- commands, shown when the query starts with ">" ----
    readonly property var commands: [
        { id: "clipboard",    title: "Clipboard",    subtitle: "Clipboard history",        icon: "edit-paste",                  mode: "clipboard" },
        { id: "switch-theme", title: "Switch theme", subtitle: "Change the colour palette", icon: "preferences-desktop-theme",   mode: "themes" },
        { id: "emoji",        title: "Emoji",        subtitle: "Pick an emoji to copy",     icon: "face-cool",                  mode: "emoji" }
    ]

    property var clipboard: []
    property var themes: []
    property var emoji: []

    // Loaded on demand: cliphist and the palettes are cheap, but there is no
    // point paying for them until the mode is actually opened.
    function load(mode) {
        if (mode === "clipboard") clipProc.running = true;
        else if (mode === "themes") themeProc.running = true;
        else if (mode === "emoji" && root.emoji.length === 0) emojiProc.running = true;
    }

    function activate(item) {
        if (item.kind === "clip")
            run("cliphist decode " + item.key + " | wl-copy");
        else if (item.kind === "theme")
            run(root.home + "/.config/themes/apply-theme.sh " + item.key);
        else if (item.kind === "emoji")
            run("printf %s " + JSON.stringify(item.key) + " | wl-copy");
    }

    // Commands run as children of quickshell, so a config reload kills them
    // partway. apply-theme.sh works around it by doing everything before it
    // rewrites Colors.qml — the write that triggers the reload. Detaching with
    // `setsid --fork` was tried instead and is not reliable here: the spawned
    // process sometimes never ran at all.
    function run(cmd) {
        runner.command = ["sh", "-c", cmd];
        runner.running = true;
    }

    Process {
        id: runner
        command: ["true"]
    }

    // scripts/clipboard.sh prints "<id>\t<preview path or empty>\t<text>",
    // decoding image entries to a cache so they can actually be shown.
    Process {
        id: clipProc
        command: [Quickshell.shellDir + "/scripts/clipboard.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of this.text.split("\n")) {
                    const parts = line.split("\t");
                    if (parts.length < 3) continue;
                    const raw = parts.slice(2).join("\t");

                    // "[[ binary data 41 KiB png 992x690 ]]" reads better as
                    // "PNG · 992x690 · 41 KiB".
                    const m = raw.match(/^\[\[\s*binary data\s+([\d.]+\s*\w+)\s+(\w+)\s+(\d+x\d+)/);
                    const title = m ? (m[2].toUpperCase() + "  ·  " + m[3] + "  ·  " + m[1]) : raw;

                    out.push({
                        kind: "clip",
                        key: parts[0],
                        title: title,
                        subtitle: m ? "Image" : "",
                        icon: "edit-paste",
                        preview: parts[1] || ""
                    });
                }
                root.clipboard = out;
            }
        }
    }

    // Each palette's slug and its display name.
    Process {
        id: themeProc
        // slug, display name, and the palette's preview wallpaper (with $HOME
        // and ~ expanded, as the palettes write it either way).
        command: ["sh", "-c",
            "for f in \"$HOME\"/.config/themes/palettes/*.conf; do "
            + "[ -e \"$f\" ] || continue; "
            + "slug=$(basename \"$f\" .conf); "
            + "name=$(sed -n 's/^THEME_NAME=\"\\(.*\\)\"/\\1/p' \"$f\" | head -1); "
            + "prev=$(sed -n 's/^preview=\"\\(.*\\)\"/\\1/p' \"$f\" | head -1); "
            + "prev=${prev/\\$HOME/$HOME}; prev=${prev/#\\~/$HOME}; "
            + "[ -f \"$prev\" ] || prev=; "
            + "printf '%s\\t%s\\t%s\\n' \"$slug\" \"$name\" \"$prev\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of this.text.split("\n")) {
                    const parts = line.split("\t");
                    if (parts.length < 2) continue;
                    out.push({
                        kind: "theme",
                        key: parts[0],
                        title: parts[1] || parts[0],
                        subtitle: parts[0],
                        icon: "preferences-desktop-theme",
                        preview: parts[2] || ""
                    });
                }
                root.themes = out;
            }
        }
    }

    // "<emoji> <description>" per line.
    Process {
        id: emojiProc
        command: ["cat", root.home + "/dotfiles/custom-scripts/emoji_list.txt"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of this.text.split("\n")) {
                    const sp = line.indexOf(" ");
                    if (sp < 0) continue;
                    out.push({
                        kind: "emoji",
                        key: line.slice(0, sp),
                        title: line.slice(0, sp),
                        subtitle: line.slice(sp + 1),
                        icon: ""
                    });
                }
                root.emoji = out;
            }
        }
    }
}
