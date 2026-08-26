// CPU, GPU, VRAM, memory and network throughput.
import QtQuick
import "root:/"
import "root:/modules"

Column {
    id: root

    // 1000-based, the way link speeds are normally quoted.
    function rate(bytesPerSec) {
        const b = bytesPerSec || 0;
        if (b >= 1000000) return (b / 1000000).toFixed(1) + " MB/s";
        if (b >= 1000) return Math.round(b / 1000) + " KB/s";
        return Math.round(b) + " B/s";
    }

    spacing: Appearance.spacing.medium

    Meter {
        label: "CPU"
        accent: Colors.sky
        percent: Stats.cpu
        detail: Stats.cpu + "%  ·  " + Stats.temp + "°C"
    }

    Meter {
        label: "GPU"
        accent: Colors.green
        percent: Stats.gpuUtil
        detail: Stats.gpuUtil + "%  ·  " + Stats.gpuTemp + "°C"
    }

    Meter {
        label: "VRAM"
        accent: Colors.teal
        percent: Stats.gpuMemTotal > 0
                 ? Math.round(Stats.gpuMem * 100 / Stats.gpuMemTotal) : 0
        detail: (Stats.gpuMem / 1024).toFixed(1) + " / "
                + (Stats.gpuMemTotal / 1024).toFixed(1) + " GiB"
    }

    Meter {
        label: "Memory"
        accent: Colors.magenta
        percent: Stats.mem
        detail: Stats.mem + "%"
    }

    Rectangle {
        width: 210
        height: 1
        color: Colors.m3outlineVariant
    }

    Item {
        width: 210
        height: netLabel.implicitHeight

        Text {
            id: netLabel
            anchors.left: parent.left
            text: "Network"
            color: Colors.m3onSurface
            font.family: Colors.font
            font.pixelSize: Appearance.fontSize.smaller
        }

        Text {
            anchors.right: parent.right
            text: Stats.online ? "Connected" : "Offline"
            color: Stats.online ? Colors.m3onSurfaceVariant : Colors.m3error
            font.family: Colors.font
            font.pixelSize: Appearance.fontSize.smaller
        }
    }

    Repeater {
        model: [
            { icon: Icons.down, name: "Down", accent: Colors.blue, value: root.rate(Stats.rxRate) },
            { icon: Icons.up,   name: "Up",   accent: Colors.teal, value: root.rate(Stats.txRate) }
        ]

        delegate: Row {
            required property var modelData
            spacing: Appearance.spacing.small

            Text {
                text: modelData.icon
                color: modelData.accent
                font.family: Colors.font
                font.pixelSize: Appearance.fontSize.normal
            }
            Text {
                text: modelData.name
                color: Colors.m3onSurfaceVariant
                font.family: Colors.font
                font.pixelSize: Appearance.fontSize.smaller
                width: 55
            }
            Text {
                text: modelData.value
                color: Colors.m3onSurface
                font.family: Colors.font
                font.pixelSize: Appearance.fontSize.smaller
            }
        }
    }
}
