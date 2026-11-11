// One adjustable volume: an icon that toggles mute, a name, the level and a
// slider. Works for any PipeWire node: an output, an input or an app stream.
import QtQuick
import Quickshell
import Quickshell.Widgets
import "root:/"

Column {
    id: root

    required property var node
    property string title: ""
    property string subtitle: ""
    // A theme icon or icon file; the glyph stands in when there isn't one.
    property string icon: ""
    property string glyph: Icons.volume
    property string mutedGlyph: Icons.muted
    property color accent: Colors.teal
    // Muted somewhere PipeWire can't see, such as a mute button on the
    // device itself. Shown as muted; the icon still toggles PipeWire's mute.
    property bool externallyMuted: false

    readonly property var audio: node ? node.audio : null
    readonly property bool muted: (audio ? audio.muted : false) || externallyMuted
    readonly property real volume: audio ? audio.volume : 0
    // Brighter versions of the colours, used while the icon or the slider
    // is hovered.
    readonly property color accentBright: Qt.lighter(accent, 1.3)
    readonly property bool iconHovered: iconMouse.containsMouse
    readonly property bool sliderHovered: sliderMouse.containsMouse || sliderMouse.pressed

    readonly property string iconSource: icon === "" ? ""
                                       : icon.startsWith("/") ? "file://" + icon
                                       : Quickshell.iconPath(icon, true)

    function setVolume(v) {
        if (root.audio)
            root.audio.volume = Math.max(0, Math.min(1, v));
    }

    width: 300
    spacing: Appearance.spacing.small

    Item {
        width: parent.width
        height: 30

        Item {
            id: iconBox
            width: 26
            height: 26
            anchors.verticalCenter: parent.verticalCenter

            // Soft disc behind the icon while it's hovered.
            Rectangle {
                anchors.centerIn: parent
                width: 34
                height: 34
                radius: width / 2
                color: Colors.m3surfaceContainerHigh
                opacity: root.iconHovered ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Appearance.anim.expressiveFastEffects } }
            }

            scale: root.iconHovered ? 1.12 : 1
            Behavior on scale { NumberAnimation { duration: Appearance.anim.expressiveFastEffects; easing.type: Easing.OutCubic } }

            IconImage {
                anchors.fill: parent
                visible: root.iconSource !== ""
                source: root.iconSource
                asynchronous: true
                opacity: root.muted ? (root.iconHovered ? 0.6 : 0.35) : 1
            }

            Text {
                anchors.centerIn: parent
                visible: root.iconSource === "" || root.muted
                text: root.muted ? root.mutedGlyph : root.glyph
                color: root.muted ? (root.iconHovered ? Colors.m3onSurface : Colors.m3onSurfaceVariant)
                                  : (root.iconHovered ? root.accentBright : root.accent)
                Behavior on color { ColorAnimation { duration: Appearance.anim.expressiveFastEffects } }
                font.family: Colors.font
                font.pixelSize: Appearance.fontSize.larger
            }

            MouseArea {
                id: iconMouse
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.audio) root.audio.muted = !root.audio.muted
            }
        }

        Column {
            anchors.left: iconBox.right
            anchors.leftMargin: Appearance.spacing.small
            anchors.right: level.left
            anchors.rightMargin: Appearance.spacing.small
            anchors.verticalCenter: parent.verticalCenter

            Text {
                width: parent.width
                text: root.title
                elide: Text.ElideRight
                color: Colors.m3onSurface
                font.family: Colors.font
                font.pixelSize: Appearance.fontSize.normal
            }
            Text {
                width: parent.width
                visible: root.subtitle !== ""
                text: root.subtitle
                elide: Text.ElideRight
                color: Colors.m3onSurfaceVariant
                font.family: Colors.font
                font.pixelSize: Appearance.fontSize.small
            }
        }

        Text {
            id: level
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.externallyMuted ? "Muted on device"
                : root.muted ? "Muted" : Math.round(root.volume * 100) + "%"
            color: Colors.m3onSurfaceVariant
            font.family: Colors.font
            font.pixelSize: Appearance.fontSize.smaller
        }
    }

    // Click or drag anywhere along the track.
    Rectangle {
        id: track
        width: parent.width
        height: 6
        radius: Appearance.rounding.full
        color: Colors.m3surfaceContainerHigh

        Rectangle {
            id: fill
            width: track.width * Math.min(1, root.volume)
            height: parent.height
            radius: parent.radius
            color: root.muted ? Colors.muted : (root.sliderHovered ? root.accentBright : root.accent)
            Behavior on color { ColorAnimation { duration: Appearance.anim.expressiveFastEffects } }
        }

        Rectangle {
            x: fill.width - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: root.sliderHovered ? 18 : 14
            height: width
            radius: width / 2
            color: root.muted ? (root.sliderHovered ? Qt.lighter(Colors.muted, 1.8) : Colors.muted)
                              : (root.sliderHovered ? root.accentBright : root.accent)
            border.width: 2
            border.color: Colors.m3surface
            Behavior on width { NumberAnimation { duration: Appearance.anim.expressiveFastEffects; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Appearance.anim.expressiveFastEffects } }
        }

        MouseArea {
            id: sliderMouse
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: function (mouse) { root.setVolume(mouse.x / track.width); }
            onPositionChanged: function (mouse) { if (pressed) root.setVolume(mouse.x / track.width); }
        }
    }

    // Scrolling over the row nudges it, like the bar's volume widget.
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function (event) {
            root.setVolume(root.volume + (event.angleDelta.y > 0 ? 0.02 : -0.02));
        }
    }
}
