// Notification daemon

import QtQuick
import Quickshell
import Quickshell.Hyprland
import QtQuick.Effects
import Quickshell.Services.Notifications
import "root:/"

Scope {
    id: root

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: function (notification) {
            notification.tracked = true;
        }
    }

    readonly property var targetScreen: {
        const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        for (let i = 0; i < Quickshell.screens.length; i++)
            if (Quickshell.screens[i].name === name)
                return Quickshell.screens[i];
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    PanelWindow {
        id: win

        screen: root.targetScreen
        anchors { top: true; right: true }
        exclusiveZone: 0
        color: "transparent"

        readonly property int corner: Appearance.rounding.large

        property real offsetScale: list.count > 0 ? 0 : 1

        Behavior on offsetScale {
            NumberAnimation {
                duration: Appearance.anim.expressiveDefaultSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.curve.expressiveDefaultSpatial
            }
        }

        visible: list.count > 0
        implicitWidth: 380 + corner
        implicitHeight: Math.max(1, column.implicitHeight + corner + Appearance.shadow.margin)

        mask: Region { item: column }

        Item {
            id: visual
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

        InvertedCorner {
            anchors.right: column.left
            y: column.y
            opacity: column.opacity
            size: win.corner
            color: Colors.m3surface
        }

        InvertedCorner {
            anchors.right: parent.right
            y: column.y + column.height
            opacity: column.opacity
            size: win.corner
            color: Colors.m3surface
        }

        Column {
            id: column
            anchors.right: parent.right
            width: parent.width - win.corner
            spacing: 0
            y: Math.min(0, (-height - 5) * win.offsetScale)
            opacity: 1 - win.offsetScale

            Repeater {
                id: list
                model: server.trackedNotifications

                delegate: Rectangle {
                    id: card
                    required property var modelData
                    required property int index

                    width: column.width
                    readonly property real fullHeight: content.implicitHeight + Appearance.padding.medium * 2
                    implicitHeight: fullHeight * collapse
                    clip: true

                    property real collapse: 1
                    property var retireAction: null
                    readonly property bool leaving: retireAction !== null

                    function retire(action) {
                        if (leaving)
                            return;
                        retireAction = action;
                        exitAnim.start();
                    }

                    NumberAnimation {
                        id: exitAnim
                        target: card
                        property: "collapse"
                        to: 0
                        duration: Appearance.anim.panel
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.bounce.exit
                        onFinished: if (card.retireAction) card.retireAction()
                    }

                    readonly property bool last: index === list.count - 1

                    color: Colors.m3surface
                    topLeftRadius: 0
                    topRightRadius: 0
                    bottomLeftRadius: last ? Appearance.rounding.large : 0
                    bottomRightRadius: 0

                    readonly property bool critical:
                        modelData.urgency === NotificationUrgency.Critical

                    // Urgency stripe down the left edge.
                    Rectangle {
                        width: 3
                        height: card.fullHeight - Appearance.padding.small * 2
                        anchors.top: parent.top
                        anchors.topMargin: Appearance.padding.small
                        anchors.left: parent.left
                        radius: Appearance.rounding.full
                        color: card.critical ? Colors.m3error : Colors.m3primary
                    }

                    Column {
                        id: content
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: Appearance.padding.medium
                        anchors.leftMargin: Appearance.padding.medium
                        anchors.rightMargin: Appearance.padding.medium
                        spacing: Appearance.spacing.extraSmall

                        Text {
                            text: card.modelData.appName
                            color: card.critical ? Colors.m3error : Colors.m3primary
                            font.family: Colors.font
                            font.pixelSize: Appearance.fontSize.small
                        }

                        Text {
                            width: parent.width
                            text: card.modelData.summary
                            color: Colors.m3onSurface
                            font.family: Colors.font
                            font.pixelSize: Appearance.fontSize.normal
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            visible: card.modelData.body.length > 0
                            text: card.modelData.body
                            color: Colors.m3onSurfaceVariant
                            font.family: Colors.font
                            font.pixelSize: Appearance.fontSize.smaller
                            wrapMode: Text.WordWrap
                            maximumLineCount: 4
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }

                        Row {
                            spacing: Appearance.spacing.small
                            visible: card.modelData.actions.length > 0
                            topPadding: Appearance.spacing.extraSmall

                            Repeater {
                                model: card.modelData.actions

                                delegate: Rectangle {
                                    required property var modelData

                                    implicitWidth: actionLabel.implicitWidth + Appearance.padding.medium * 2
                                    implicitHeight: 24
                                    radius: Appearance.rounding.full
                                    color: actionMouse.containsMouse ? Colors.m3primary
                                                                     : Colors.m3surfaceContainerHigh

                                    Text {
                                        id: actionLabel
                                        anchors.centerIn: parent
                                        text: modelData.text
                                        color: actionMouse.containsMouse ? Colors.m3onPrimary
                                                                         : Colors.m3onSurface
                                        font.family: Colors.font
                                        font.pixelSize: Appearance.fontSize.small
                                    }

                                    MouseArea {
                                        id: actionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: modelData.invoke()
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        z: -1
                        onClicked: card.retire(() => card.modelData.dismiss())
                    }

                    Timer {
                        running: !card.critical && !card.leaving
                        interval: card.modelData.expireTimeout > 0
                                  ? card.modelData.expireTimeout
                                  : 5000
                        onTriggered: card.retire(() => card.modelData.expire())
                    }
                }
            }
        }
        }
    }
}
