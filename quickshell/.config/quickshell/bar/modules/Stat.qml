import QtQuick
import "root:/"

Text {
    property string icon: ""
    property string value: ""

    text: icon + " " + value
    font.family: Colors.font
    font.pixelSize: Appearance.fontSize.normal
    verticalAlignment: Text.AlignVCenter
    rightPadding: Appearance.spacing.small
}
