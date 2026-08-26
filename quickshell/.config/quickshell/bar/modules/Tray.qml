import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "root:/"

Row {
    id: root

    spacing: Appearance.spacing.small

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: entry
            required property var modelData

            implicitWidth: 16
            implicitHeight: 16
            anchors.verticalCenter: parent.verticalCenter

            IconImage {
                id: img
                anchors.fill: parent
                source: entry.modelData.icon
                // Dim until hovered, so a row of tray icons stays quiet.
                opacity: mouse.containsMouse ? 1 : 0.75

                Behavior on opacity {
                    NumberAnimation { duration: Appearance.anim.small }
                }
            }

            HitArea {
                id: mouse
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                function openMenu() {
                    Panels.trayItem = entry.modelData;
                    Panels.open("tray", entry.mapToItem(null, entry.width / 2, 0).x,
                                entry.QsWindow.window.screen);
                }

                // Clicking an icon opens its menu; it retracts when the pointer
                // leaves, like every other panel.
                onClicked: function (mouse) {
                    if (mouse.button === Qt.MiddleButton)
                        entry.modelData.secondaryActivate();
                    else if (entry.modelData.hasMenu)
                        openMenu();
                    else if (mouse.button === Qt.LeftButton)
                        entry.modelData.activate();
                }
                onEntered: Panels.setHovered("tray", true)
                onExited: { Panels.setHovered("tray", false); Panels.cancelPending("tray"); }
            }
        }
    }
}
