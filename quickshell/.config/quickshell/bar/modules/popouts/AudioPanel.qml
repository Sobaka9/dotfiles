// Volume mixer: the default output and input, then every app playing sound,
// one row per stream (two browser tabs get two sliders). Values come from
// PipeWire directly, and rows come and go as apps start and stop playing.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "root:/"

Column {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    // Every stream is tracked, because PipeWire objects only publish their
    // properties (media.class, names) and volumes while tracked; playback
    // streams are then picked out by their media class.
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream)
    readonly property var playing: streams.filter(n =>
        (n.properties["media.class"] || "") === "Stream/Output/Audio" && n.audio
        && !root.hiddenClients.includes(String(n.properties["client.id"])))

    // Programs whose streams are left out of the list. Wallpaper engine's
    // video wallpapers play through mpv and stay muted (--silent), so they
    // were permanent dead rows. Their streams only say "mpv"; the PipeWire
    // client that owns them names the program, and Quickshell doesn't expose
    // clients, so scripts/pw-clients.py looks up those clients' ids. It runs
    // at start and whenever the set of streams changes, which also covers
    // wallpaper engine being restarted. An mpv you start yourself still shows.
    readonly property var hiddenApps: ["linux-wallpaperengine"]
    property var hiddenClients: []

    Process {
        id: clientScan
        running: true
        command: [Quickshell.shellDir + "/scripts/pw-clients.py"].concat(root.hiddenApps)
        stdout: StdioCollector {
            onStreamFinished: root.hiddenClients = text.split("\n").filter(l => l !== "")
        }
    }
    onStreamsChanged: clientScan.running = true

    PwObjectTracker {
        objects: [root.sink, root.source].filter(n => n).concat(root.streams)
    }

    // ---- Mic muted on the device ----
    // The QuadCast's tap-to-mute happens inside the mic: nothing in ALSA or
    // PipeWire changes. While muted it streams a fixed tiny signal (peaks of
    // 769-1025) where, unmuted, even a silent room peaks at 14000+ at its
    // gain. So while this panel is open, and only then, its level is read
    // (peak numbers only, see scripts/micpeak.py) and two quiet readings in a
    // row (0.4s) count as muted. Limited to the QuadCast: those levels are
    // its own, and on another mic silence could pass for muted.
    readonly property bool sourceIsQuadCast: (root.source?.description ?? "").includes("QuadCast")
    readonly property bool panelOpen: Panels.hasCurrent && Panels.currentName === "audio"
    property bool micMutedOnDevice: false
    property int peakReadings: 0
    property int quietRun: 0
    property int loudRun: 0

    Process {
        running: root.panelOpen && root.sourceIsQuadCast && root.source
        command: [Quickshell.shellDir + "/scripts/micpeak.py", root.source ? root.source.name : ""]
        onRunningChanged: {
            root.peakReadings = 0;
            root.quietRun = 0;
            root.loudRun = 0;
        }
        stdout: SplitParser {
            onRead: function (line) {
                const peak = parseInt(line);
                // The first reading is a start-up spike, not the mic.
                if (isNaN(peak) || root.peakReadings++ === 0)
                    return;
                if (peak < 4000) {
                    root.quietRun++;
                    root.loudRun = 0;
                } else {
                    root.loudRun++;
                    root.quietRun = 0;
                }
                if (root.quietRun >= 2)
                    root.micMutedOnDevice = true;
                else if (root.loudRun >= 2)
                    root.micMutedOnDevice = false;
            }
        }
    }

    function nodeName(n) {
        return n ? (n.description || n.nickname || n.name || "") : "";
    }

    function iconExists(name) {
        return !!name && (name.startsWith("/") || Quickshell.iconPath(name, true) !== "");
    }

    // An icon for an app stream, from its PipeWire properties. Each candidate
    // is checked to exist, since what apps send is often unusable as is:
    // Stremio names "Stremio" where the theme has "stremio", and Zen sends
    // nothing. In order: the icon the app names (also lowercased); its desktop
    // entry, looked up by app name, id or binary; a desktop entry whose name's
    // first word begins the app's name, so "HytaleClient" finds the "Hytale
    // Launcher" entry (at least four letters, to avoid chance matches); and
    // the app or binary name itself as an icon name.
    function appIcon(n) {
        // Read first so a row re-resolves once the desktop entries have
        // loaded; a row created before then otherwise kept a missing icon.
        const entries = DesktopEntries.applications.values;
        const p = n.properties;
        const name = p["application.name"] || "";
        const id = p["application.id"] || "";
        const bin = (p["application.process.binary"] || "").replace(/-bin$/, "");
        const given = p["application.icon-name"] || "";

        for (const c of [given, given.toLowerCase()])
            if (iconExists(c))
                return c;

        for (const guess of [name, id, bin]) {
            if (guess === "")
                continue;
            const entry = DesktopEntries.heuristicLookup(guess);
            if (entry && iconExists(entry.icon))
                return entry.icon;
        }

        const key = (name || bin).toLowerCase().replace(/[^a-z0-9]/g, "");
        if (key.length >= 4) {
            for (const e of entries) {
                const word = (e.name || "").toLowerCase().split(/\s+/)[0].replace(/[^a-z0-9]/g, "");
                if (word.length >= 4 && key.startsWith(word) && iconExists(e.icon))
                    return e.icon;
            }
        }

        for (const c of [name.toLowerCase(), bin])
            if (iconExists(c))
                return c;
        return "";
    }

    spacing: Appearance.spacing.medium

    component Heading: Text {
        color: Colors.m3onSurfaceVariant
        font.family: Colors.font
        font.pixelSize: Appearance.fontSize.small
        font.bold: true
    }

    Heading { text: "Output" }
    VolumeRow {
        node: root.sink
        title: root.nodeName(root.sink) || "No output"
    }

    Heading { text: "Input"; visible: root.source !== null }
    VolumeRow {
        visible: root.source !== null
        node: root.source
        title: root.nodeName(root.source)
        glyph: Icons.mic
        mutedGlyph: Icons.micOff
        externallyMuted: root.sourceIsQuadCast && root.micMutedOnDevice
        accent: Colors.m3primary
    }

    Heading { text: "Applications" }
    Text {
        visible: root.playing.length === 0
        text: "Nothing is playing"
        color: Colors.m3outline
        font.family: Colors.font
        font.pixelSize: Appearance.fontSize.smaller
    }
    // At most `maxRows` apps show at once; past that the list scrolls, as
    // the popout's window has a fixed height and a long list was cut off.
    // The list reaches `bleed` px past the rows on each side so it doesn't
    // clip the hover disc behind the icons or the knob at either end.
    Item {
        id: apps
        visible: root.playing.length > 0
        readonly property int maxRows: 4
        readonly property int bleed: 10
        readonly property real rowHeight: appList.count > 0 && appList.itemAtIndex(0)
                                          ? appList.itemAtIndex(0).height : 44
        width: 300
        height: Math.min(appList.contentHeight,
                         maxRows * rowHeight + (maxRows - 1) * appList.spacing) + bleed

        ListView {
            id: appList
            x: -apps.bleed
            width: apps.width + apps.bleed * 2
            height: parent.height
            clip: true
            spacing: Appearance.spacing.medium
            bottomMargin: apps.bleed
            // Rows are indented by the list's margin: ListView positions its
            // rows itself and ignored an x set on them, which left the app
            // rows 10px left of the output and input rows.
            leftMargin: apps.bleed
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight + bottomMargin > height

            model: ScriptModel { values: root.playing }
            delegate: VolumeRow {
                required property var modelData
                node: modelData
                title: modelData.properties["application.name"] || root.nodeName(modelData)
                subtitle: modelData.properties["media.name"] || ""
                icon: root.appIcon(modelData)
                glyph: Icons.app
            }
        }

        // Slim scroll indicator, only when the list is longer than shown.
        Rectangle {
            visible: appList.interactive
            x: apps.width + apps.bleed / 2 - width / 2
            width: 3
            radius: width / 2
            color: Colors.m3outline
            readonly property real visibleFraction: appList.height / (appList.contentHeight + appList.bottomMargin)
            height: Math.max(16, appList.height * visibleFraction)
            y: (appList.height - height) * (appList.contentY - appList.originY)
               / Math.max(1, appList.contentHeight + appList.bottomMargin - appList.height)
        }
    }
}
