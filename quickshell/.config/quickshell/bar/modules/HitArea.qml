import QtQuick
import "root:/"

MouseArea {
    property int slop: Appearance.spacing.extraSmall
    property int leftSlop: slop
    property int rightSlop: slop

    anchors.fill: parent
    anchors.topMargin: -(Appearance.barHeight - parent.height) / 2
    anchors.bottomMargin: -(Appearance.barHeight - parent.height) / 2
    anchors.leftMargin: -leftSlop
    anchors.rightMargin: -rightSlop

    hoverEnabled: true
}
