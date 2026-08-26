// The menu belonging to whichever tray item is currently hovered.
import QtQuick
import Quickshell
import "root:/"

Column {
    id: root

    spacing: 0

    QsMenuOpener {
        id: opener
        menu: Panels.trayItem ? Panels.trayItem.menu : null
    }

    Repeater {
        model: opener.children

        delegate: Item {
            required property var modelData

            implicitWidth: 180
            implicitHeight: modelData.isSeparator ? 9 : 28

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                visible: !modelData.isSeparator
                radius: Appearance.rounding.small
                color: itemMouse.containsMouse ? Colors.m3surfaceContainerHigh : "transparent"
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 1
                visible: modelData.isSeparator
                color: Colors.m3outlineVariant
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Appearance.padding.small
                width: parent.width - Appearance.padding.small * 2
                visible: !modelData.isSeparator
                text: modelData.text
                elide: Text.ElideRight
                color: modelData.enabled ? Colors.m3onSurface : Colors.m3outline
                font.family: Colors.font
                font.pixelSize: Appearance.fontSize.smaller
            }

            MouseArea {
                id: itemMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: !modelData.isSeparator && modelData.enabled
                onClicked: {
                    modelData.triggered();
                    Panels.close();
                }
            }
        }
    }
}
