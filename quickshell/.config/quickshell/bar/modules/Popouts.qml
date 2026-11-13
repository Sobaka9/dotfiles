// The popout container for one monitor.

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "root:/"
import "popouts"

PanelWindow {
    id: root

    required property var targetScreen
    // The launcher's state (Launcher.qml). Not named `launcher`: in shell.qml
    // `launcher: launcher` would then read this property, not the launcher.
    required property var launcherState

    readonly property bool active: Panels.hasCurrent && Panels.currentScreen === root.targetScreen
    // Any part of a panel is still showing, including while it retracts.
    readonly property bool onScreen: offsetScale < 1
    screen: targetScreen
    anchors { top: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    // Same layer as the bar (see shell.qml), which is drawn beneath it.
    WlrLayershell.layer: WlrLayer.Overlay
    // The keyboard only while the launcher is the panel showing here.
    WlrLayershell.keyboardFocus: root.active && Panels.currentName === "launcher"
                                 ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    visible: true

    mask: Region {
        x: clipper.x
        y: 0
        width: clipper.height > 0 ? clipper.width : 0
        height: clipper.height
    }

    readonly property int corner: Appearance.rounding.large
    readonly property int pad: Appearance.padding.large

    // Size of whichever panel is loaded, morphed between panels.
    readonly property Item currentPanel: {
        for (let i = 0; i < panels.children.length; i++)
            if (panels.children[i].shouldBeActive)
                return panels.children[i];
        return null;
    }
    // Size the panel is heading for, before any animation.
    readonly property real targetWidth: currentPanel ? currentPanel.implicitWidth + pad * 2 : 0
    readonly property real targetHeight: currentPanel ? currentPanel.implicitHeight + pad * 2 : 0

    property real panelWidth: targetWidth
    property real panelHeight: targetHeight

    Behavior on panelWidth {
        enabled: root.offsetScale < 1
        PanelAnim {}
    }
    Behavior on panelHeight {
        enabled: root.offsetScale < 1
        PanelAnim {}
    }

    readonly property real maxX: Math.max(0, width - targetWidth)

    readonly property real maxXNow: Math.max(0, width - panelWidth)

    property real slideX: Math.max(0, Math.min(maxX, Panels.currentCenter - targetWidth / 2))

    Behavior on slideX {
        enabled: root.offsetScale < 1
        PanelAnim {}
    }

    readonly property real surfaceX: Math.round(Math.max(0, Math.min(maxXNow, slideX)))
    readonly property real surfaceWidth: Math.round(panelWidth)

    // How much of the panel is currently revealed.
    // Whole pixels: the panel now moves, and at fractional positions its text
    // (snapped to the pixel grid) and its edges (not snapped) stepped
    // unevenly against each other, which read as jitter.
    readonly property real surfaceHeight: Math.round(Math.max(0, panelHeight * (1 - offsetScale)))

    // The fillets and the panel's bottom corners share its height, each
    // getting at most half, so they always meet on a straight stretch of
    // side; a full-size fillet beside a short panel left a sliver of
    // background between them in the last frames of every close.
    readonly property real revealCorner: Math.max(0, Math.min(corner, surfaceHeight / 2))
    readonly property real bottomRadius: Math.max(0, Math.min(Appearance.rounding.large, surfaceHeight / 2))

    readonly property bool flushLeft: surfaceX <= 0.5
    readonly property bool flushRight: surfaceX >= maxXNow - 0.5

    // Tall enough for the launcher at its full eight rows.
    implicitHeight: 640

    property real offsetScale: 1
    onActiveChanged: {
        // The launcher opens on a gentler curve than the bounce: on a panel
        // that tall the bounce's ~9% overshoot was a visible lurch.
        offsetAnim.easing.bezierCurve = !root.active ? Appearance.bounce.exit
            : Panels.currentName === "launcher" ? Appearance.curve.expressiveDefaultSpatial
            : Appearance.bounce.curve;
        root.offsetScale = root.active ? 0 : 1;
    }
    Behavior on offsetScale {
        NumberAnimation {
            id: offsetAnim
            duration: Appearance.anim.panel
            easing.type: Easing.BezierSpline
        }
    }

    component PanelAnim: NumberAnimation {
        duration: Appearance.anim.panel
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.curve.expressiveDefaultSpatial
    }

    Item {
        id: shadowLayer

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

        Item {
            id: clipper

            x: root.surfaceX - root.corner
            width: root.surfaceWidth + root.corner * 2
            anchors.top: parent.top

            height: root.surfaceHeight
            visible: height > 0
            clip: true

            HoverHandler {
                onHoveredChanged: {
                    Panels.setHovered("panel", hovered);
                    if (hovered)
                        Panels.keepOpen();
                }
            }

        Rectangle {
            id: surface

            x: root.corner
            width: root.surfaceWidth

            height: root.surfaceHeight
            y: 0

            color: Colors.m3surface
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: root.flushLeft ? 0 : root.bottomRadius
            bottomRightRadius: root.flushRight ? 0 : root.bottomRadius

            InvertedCorner {
                anchors.right: parent.left
                anchors.top: parent.top
                visible: !root.flushLeft
                size: root.revealCorner
                color: surface.color
            }

            InvertedCorner {
                anchors.left: parent.right
                anchors.top: parent.top
                visible: !root.flushRight
                size: root.revealCorner
                color: surface.color
                mirrored: true
            }
        }

        Item {
            id: panels

            x: surface.x + root.pad
            y: root.pad
            width: Math.max(0, surface.width - root.pad * 2)
            height: Math.max(0, root.panelHeight - root.pad * 2)

            Panel { name: "clock";  sourceComponent: ClockPanel {} }
            Panel { name: "audio";  sourceComponent: AudioPanel {} }
            Panel { name: "system"; sourceComponent: SystemPanel {} }
            Panel { name: "power";  sourceComponent: PowerPanel {} }
            Panel { name: "tray";   sourceComponent: TrayPanel {} }
            Panel { name: "launcher"; sourceComponent: LauncherPanel { launcher: root.launcherState } }
        }
        }
    }

    component Panel: Loader {
        id: panel

        required property string name
        readonly property bool shouldBeActive: Panels.currentName === name

        anchors.left: parent.left
        anchors.top: parent.top

        active: true
        visible: panel.shouldBeActive
    }
}
