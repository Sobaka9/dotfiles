// Shutdown and reboot.
import QtQuick
import Quickshell.Io
import "root:/"

Column {
    id: root

    spacing: 2

    Process {
        id: runner
        command: ["true"]
    }

    function run(action) {
        runner.command = ["sh", "-c",
            "if command -v hyprshutdown >/dev/null; then hyprshutdown -p '" + action + "'; else " + action + "; fi"];
        runner.running = true;
        Panels.close();
    }

    Repeater {
        model: [
            { label: "Shutdown", icon: Icons.power,  action: "systemctl poweroff", accent: Colors.red },
            { label: "Reboot",   icon: Icons.reboot, action: "systemctl reboot",   accent: Colors.yellow }
        ]

        delegate: Rectangle {
            required property var modelData
            width: 150
            height: 30
            radius: Appearance.rounding.small
            color: entry.containsMouse ? Colors.m3surfaceContainerHigh : "transparent"

            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Appearance.padding.small
                spacing: Appearance.spacing.medium

                Text {
                    text: modelData.icon
                    color: modelData.accent
                    font.family: Colors.font
                    font.pixelSize: Appearance.fontSize.normal
                }
                Text {
                    text: modelData.label
                    color: Colors.m3onSurface
                    font.family: Colors.font
                    font.pixelSize: Appearance.fontSize.normal
                }
            }

            MouseArea {
                id: entry
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.run(modelData.action)
            }
        }
    }
}
