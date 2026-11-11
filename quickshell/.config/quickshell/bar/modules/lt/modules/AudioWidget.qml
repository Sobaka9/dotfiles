import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "root:/"

Text {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var sinkAudio: sink ? sink.audio : null
    readonly property bool muted: sinkAudio ? sinkAudio.muted : false
    readonly property int volumePct: sinkAudio ? Math.round(sinkAudio.volume * 100) : 0

    // Pipewire objects only publish their properties while tracked.
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    text: (muted ? Icons.muted : Icons.volume) + " " + (muted ? "" : volumePct + "%")
    color: Colors.teal
    font.family: Colors.font
    font.pixelSize: Appearance.fontSize.normal
    verticalAlignment: Text.AlignVCenter
    rightPadding: Appearance.spacing.small

    HitArea {
        onWheel: function (wheel) {
            if (!root.sinkAudio) return;
            const step = wheel.angleDelta.y > 0 ? 0.01 : -0.01;
            root.sinkAudio.volume = Math.max(0, Math.min(1, root.sinkAudio.volume + step));
        }
        onEntered: { Panels.setHovered("audio", true); Panels.open("audio", root.mapToItem(null, root.width / 2, 0).x, root.QsWindow.window.screen); }
        onExited: { Panels.setHovered("audio", false); Panels.cancelPending("audio"); }
        onClicked: Panels.hasCurrent ? Panels.close()
                                     : Panels.open("audio", root.mapToItem(null, root.width / 2, 0).x, root.QsWindow.window.screen)
    }
}
