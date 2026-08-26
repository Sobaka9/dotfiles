// Volume: mute toggle and a slider. Values come from Pipewire directly.
import QtQuick
import Quickshell.Services.Pipewire
import "root:/"

Column {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var sinkAudio: sink ? sink.audio : null
    readonly property bool muted: sinkAudio ? sinkAudio.muted : false
    readonly property int volumePct: sinkAudio ? Math.round(sinkAudio.volume * 100) : 0

    // Pipewire objects only publish their properties while tracked.
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    spacing: Appearance.spacing.medium

    Row {
        spacing: Appearance.spacing.small

        Text {
            text: root.muted ? Icons.muted : Icons.volume
            color: root.muted ? Colors.muted : Colors.teal
            font.family: Colors.font
            font.pixelSize: Appearance.fontSize.larger

            MouseArea {
                anchors.fill: parent
                onClicked: if (root.sinkAudio) root.sinkAudio.muted = !root.sinkAudio.muted
            }
        }

        Text {
            text: root.muted ? "Muted" : root.volumePct + "%"
            color: Colors.m3onSurface
            font.family: Colors.font
            font.pixelSize: Appearance.fontSize.normal
        }
    }

    // Hand-rolled slider: click or drag anywhere along the track.
    Rectangle {
        id: track
        width: 240
        height: 6
        radius: Appearance.rounding.full
        color: Colors.m3surfaceContainerHigh

        Rectangle {
            id: fill
            width: track.width * (root.sinkAudio ? root.sinkAudio.volume : 0)
            height: parent.height
            radius: parent.radius
            color: root.muted ? Colors.muted : Colors.teal
        }

        // Knob at the end of the fill.
        Rectangle {
            x: fill.width - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            radius: width / 2
            color: root.muted ? Colors.muted : Colors.teal
            border.width: 2
            border.color: Colors.m3surface
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            function setFromX(x) {
                if (!root.sinkAudio) return;
                root.sinkAudio.volume = Math.max(0, Math.min(1, x / track.width));
            }
            onPressed: function (mouse) { setFromX(mouse.x); }
            onPositionChanged: function (mouse) { if (pressed) setFromX(mouse.x); }
        }
    }
}
