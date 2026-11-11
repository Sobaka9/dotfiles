// Workspace indicators for one monitor.

import QtQuick
import Quickshell.Hyprland
import "root:/"

Row {
    id: root

    required property string monitorName

    spacing: Appearance.spacing.extraSmall

    Repeater {
        model: Hyprland.workspaces

        delegate: Rectangle {
            id: chip
            required property var modelData

            visible: modelData.monitor && modelData.monitor.name === root.monitorName

            readonly property bool current: modelData.active

            implicitWidth: current ? label.implicitWidth + Appearance.padding.medium * 2
                                   : label.implicitWidth + Appearance.padding.small
            implicitHeight: 20
            radius: Appearance.rounding.full
            color: current ? Colors.m3primary : "transparent"

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Appearance.anim.expressiveFastSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.curve.expressiveDefaultSpatial
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: Appearance.anim.small
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.curve.standard
                }
            }

            Text {
                id: label
                anchors.centerIn: parent
                text: chip.modelData.name
                color: chip.current ? Colors.m3onPrimary
                                    : (hover.hovered ? Colors.m3onSurface : Colors.m3outline)
                font.family: Colors.font
                font.pixelSize: Appearance.fontSize.normal
                font.bold: chip.current

                Behavior on color {
                    ColorAnimation { duration: Appearance.anim.small }
                }
            }

            HoverHandler { id: hover }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + chip.modelData.id + " })")
            }
        }
    }
}
