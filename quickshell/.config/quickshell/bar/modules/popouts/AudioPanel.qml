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
        (n.properties["media.class"] || "") === "Stream/Output/Audio" && n.audio)

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

    // The app's own icon if it names one, else its desktop entry's, found
    // from the app or binary name (Zen, for one, sends no icon).
    function appIcon(n) {
        const p = n.properties;
        if (p["application.icon-name"])
            return p["application.icon-name"];
        const bin = (p["application.process.binary"] || "").replace(/-bin$/, "");
        for (const guess of [p["application.name"] || "", bin]) {
            if (guess === "")
                continue;
            const entry = DesktopEntries.heuristicLookup(guess);
            if (entry && entry.icon)
                return entry.icon;
        }
        return bin;
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
    Repeater {
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
}
