// Quickshell bar

import QtQuick
import Quickshell
import Quickshell.Hyprland
import QtQuick.Effects
import "modules"

ShellRoot {
    // Notification daemon
    Notifications { }

    // Application launcher
    Launcher { }

    Variants {
        // One bar per monitor.
        model: Quickshell.screens

        Scope {
            id: perScreen
            required property var modelData

        PanelWindow {
            id: bar

            screen: perScreen.modelData
            anchors { top: true; left: true; right: true }

            implicitHeight: Appearance.barHeight + Appearance.rounding.large
            exclusiveZone: Appearance.barHeight
            color: "transparent"

            Item {
                id: barVisual
                anchors.fill: parent

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: Appearance.shadow.blur
                    shadowColor: "black"
                    shadowOpacity: Appearance.shadow.opacity
                    shadowVerticalOffset: Appearance.shadow.yOffset
                    autoPaddingEnabled: true
                    blurMax: 32
                }

                Rectangle {
                    id: barFill
                    anchors.top: parent.top
                    width: parent.width
                    height: Appearance.barHeight
                    color: Colors.m3surface
                }

                InvertedCorner {
                    anchors.left: parent.left
                    anchors.top: barFill.bottom
                    size: Appearance.rounding.large
                    color: barFill.color
                    mirrored: true
                }

                InvertedCorner {
                    anchors.right: parent.right
                    anchors.top: barFill.bottom
                    size: Appearance.rounding.large
                    color: barFill.color
                }
            }

            Item {
                id: surface
                anchors.top: parent.top
                width: parent.width
                height: Appearance.barHeight
            }

            // ---- left: clock, workspaces ----
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: surface.verticalCenter
                spacing: 12

                ClockWidget { anchors.verticalCenter: surface.verticalCenter }

                Workspaces {
                    anchors.verticalCenter: surface.verticalCenter
                    monitorName: perScreen.modelData.name
                }

                Tray { anchors.verticalCenter: surface.verticalCenter }
            }

            // ---- centre: focused window ----
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: surface.verticalCenter
                width: Math.min(implicitWidth, bar.width * 0.4)
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
                color: Colors.m3onSurface
                font.family: Colors.font
                font.pixelSize: Appearance.fontSize.normal
            }

            // ---- right: stats, power ----
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: surface.verticalCenter
                spacing: 0

                AudioWidget { }

                SystemWidget { }

                PowerWidget { }
            }
        }

            // One popout container per monitor, shared by every widget.
            Popouts { targetScreen: perScreen.modelData }
        }
    }
}
