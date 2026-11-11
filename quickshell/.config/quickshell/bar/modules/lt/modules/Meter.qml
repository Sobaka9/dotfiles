// One labelled row in the system panel: name, reading, and a filled bar.
import QtQuick
import "root:/"

Column {
    id: root

    property string label: ""
    property string detail: ""
    property int percent: 0
    property color accent: Colors.m3primary

    spacing: Appearance.spacing.extraSmall
    width: 210

    Item {
        width: parent.width
        height: nameLabel.implicitHeight

        Text {
            id: nameLabel
            anchors.left: parent.left
            text: root.label
            color: Colors.m3onSurface
            font.family: Colors.font
            font.pixelSize: Appearance.fontSize.smaller
        }

        Text {
            anchors.right: parent.right
            text: root.detail
            color: Colors.m3onSurfaceVariant
            font.family: Colors.font
            font.pixelSize: Appearance.fontSize.smaller
        }
    }

    Rectangle {
        width: parent.width
        height: 4
        radius: Appearance.rounding.full
        color: Colors.m3surfaceContainerHigh

        Rectangle {
            width: parent.width * Math.max(0, Math.min(100, root.percent)) / 100
            height: parent.height
            radius: parent.radius
            color: root.accent

            Behavior on width {
                NumberAnimation {
                    duration: Appearance.anim.small
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.curve.standard
                }
            }
        }
    }
}
