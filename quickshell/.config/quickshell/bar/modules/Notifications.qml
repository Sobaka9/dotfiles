// Notification daemon

import QtQuick
import Quickshell
import Quickshell.Hyprland
import QtQuick.Effects
import Quickshell.Services.Notifications
import Quickshell.Wayland
import Quickshell.Widgets
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
        color: "transparent"
        // Same layer as the bar (see shell.qml), which is drawn beneath it.
        WlrLayershell.layer: WlrLayer.Overlay

        // With a fullscreen window on this monitor the bar is hidden beneath
        // it but still reserves its space, so a stack hung off the bar floated
        // below an empty strip, with corners shaped to join a bar that wasn't
        // there. Instead it becomes a free-standing toast in the screen's
        // corner: it ignores the bar's reserved space, sits `inset` in from
        // the edges (room for its shadow), drops the fillet and rounds every
        // outer corner.
        // True only for a window that is really fullscreen. Hyprland's
        // workspace `hasFullscreen` is also set by a maximized window (its
        // fullscreen mode 1), which hid the bar over a maximized browser;
        // the Wayland fullscreen state is only set for real fullscreen.
        readonly property bool floating:
            (Hyprland.focusedMonitor?.activeWorkspace?.toplevels.values ?? [])
                .some(t => t.wayland?.fullscreen ?? false)
        readonly property int inset: floating ? corner : 0
        // The window always sits at the very top of the screen, at a fixed
        // width, ignoring the bar's reserved space; the stack is placed inside
        // it (`topOffset`, `inset`). Moving or resizing the window itself when
        // it switched monitors and modes at the same moment didn't reliably
        // land, which left the stack at the top of a screen whose bar was up,
        // or under a bar that wasn't.
        exclusionMode: ExclusionMode.Ignore
        readonly property int topOffset: floating ? inset : Appearance.barHeight

        readonly property int corner: Appearance.rounding.large

        // How much of the stack is showing, and a fillet size that tracks it.
        // Cards grow in and shrink out on their own (see `collapse` on the
        // card), with the popouts' timing and curves, so the stack is simply
        // as tall as its cards are right now.
        readonly property real revealHeight: column.implicitHeight
        // The fillets and the stack's bottom corners share the stack's height:
        // each gets at most half of it. A fillet as tall as a short stack sat
        // beside the stack's bottom corner as it rounded away, leaving a sliver
        // of background between them in the last frames of every close.
        readonly property real revealCorner: Math.max(0, Math.min(corner, revealHeight / 2))

        visible: list.count > 0
        implicitWidth: 380 + corner * 2
        // The window never shrinks while it is shown, and grows straight to
        // the height the cards are heading for. It used to track the stack
        // exactly, which resized the Wayland surface on every frame of a card
        // animating; each resize waits on the compositor, so the animation
        // only advanced ~60 times a second. reserve() sums the cards' final
        // heights, plus room for the bounce's overshoot, so a card growing in
        // costs one resize at most. The peak resets when the stack empties and
        // the window unmaps; the mask keeps the slack click-through.
        property real peakHeight: 0
        readonly property int cardCount: list.count
        onCardCountChanged: if (cardCount === 0) peakHeight = 0

        function reserve() {
            let total = 0, tallest = 0;
            for (let i = 0; i < column.children.length; i++) {
                const c = column.children[i];
                if (c.fullHeight === undefined)
                    continue;   // the Repeater itself
                total += c.leaving ? c.implicitHeight : c.fullHeight;
                tallest = Math.max(tallest, c.fullHeight);
            }
            peakHeight = Math.max(peakHeight,
                                  Math.ceil(total + tallest * Appearance.bounce.overshoot));
        }

        implicitHeight: Math.max(1, peakHeight + Appearance.shadow.margin + topOffset)

        mask: Region { item: clipper }

        // Under the bar, nothing may be drawn above its bottom edge: the cards'
        // shadow would otherwise darken the bar, which sits beneath this
        // window. Floating, the whole window is fair game.
        Item {
            anchors.fill: parent
            anchors.topMargin: win.floating ? 0 : Appearance.barHeight
            clip: true

        Item {
            id: visual
            anchors.fill: parent
            anchors.topMargin: -parent.anchors.topMargin

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

            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: win.inset
            anchors.topMargin: win.topOffset
            width: 380 + win.corner
            height: win.revealHeight
            visible: height > 0
            clip: true

        InvertedCorner {
            anchors.right: column.left
            y: 0
            visible: !win.floating
            size: win.revealCorner
            color: Colors.m3surface
        }

        Column {
            id: column
            anchors.right: parent.right
            width: parent.width - win.corner
            spacing: 0
            y: 0

            Repeater {
                id: list
                model: server.trackedNotifications

                // Each card sits in a slot whose height is what animates, so
                // the stack reflows around it; the card shrinks with it.
                // Floating over a fullscreen window it fades out first and
                // then folds (see exitAnim).
                delegate: Item {
                    id: slot
                    required property var modelData
                    required property int index

                    width: column.width
                    // Whole pixels: the panel now moves, and at fractional positions its text
                    // (snapped to the pixel grid) and its edges (not snapped) stepped
                    // unevenly against each other, which read as jitter.
                    implicitHeight: Math.round(card.fullHeight * card.collapse)
                    clip: true

                    // Read by win.reserve().
                    readonly property real fullHeight: card.fullHeight
                    readonly property bool leaving: card.leaving

                Rectangle {
                    id: card
                    readonly property var modelData: slot.modelData
                    readonly property int index: slot.index

                    width: slot.width
                    height: slot.height

                    // The picture a notification carries (Discord's sender avatar,
                    // album art, a screenshot thumbnail...), shown beside the text.
                    // The slot is a fixed 48px tall, so the card doesn't jump
                    // while the image loads, and is dropped if it can't be
                    // loaded. Its width follows the picture's shape up to 2:1,
                    // so a screenshot reads as a screenshot rather than a
                    // square crop from its middle.
                    readonly property int imageSize: 48
                    readonly property real imageAspect: avatar.status === Image.Ready
                                                        && avatar.implicitHeight > 0
                                                        ? avatar.implicitWidth / avatar.implicitHeight : 1
                    readonly property real imageWidth: Math.round(Math.max(imageSize,
                                                         Math.min(imageSize * 2, imageSize * imageAspect)))

                    // Quickshell hands over raw pixels (Discord's avatars) as
                    // image://qsimage/..., and an image-path hint or app icon as
                    // image://icon/<path or icon name>. Qt's icon provider draws
                    // a checkerboard for anything it can't find instead of
                    // failing, so resolve those here: files load directly (a
                    // missing one errors cleanly) and icon names only if the
                    // theme has them.
                    readonly property string imageSource: {
                        const img = modelData.image || "";
                        if (!img.startsWith("image://icon/"))
                            return img;
                        const name = img.slice("image://icon/".length);
                        if (name.startsWith("/"))
                            return "file://" + name;
                        if (name.startsWith("file://"))
                            return name;
                        return Quickshell.iconPath(name, true);
                    }
                    readonly property bool hasImage: imageSource !== ""
                                                     && avatar.status !== Image.Error

                    readonly property real fullHeight: Math.max(content.implicitHeight,
                                                                hasImage ? imageSize : 0)
                                                       + Appearance.padding.medium * 2
                    clip: true

                    // 0 = folded away, 1 = fully open. Cards open and close with
                    // the popouts' timing and curves.
                    property real collapse: 0
                    property var retireAction: null
                    readonly property bool leaving: retireAction !== null

                    Component.onCompleted: {
                        enterAnim.start();
                        Qt.callLater(win.reserve);
                    }
                    onFullHeightChanged: Qt.callLater(win.reserve)

                    function retire(action) {
                        if (leaving)
                            return;
                        enterAnim.stop();
                        retireAction = action;
                        exitAnim.start();
                    }

                    NumberAnimation {
                        id: enterAnim
                        target: card
                        property: "collapse"
                        to: 1
                        duration: Appearance.anim.panel
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.bounce.curve
                    }

                    SequentialAnimation {
                        id: exitAnim
                        NumberAnimation {
                            target: card
                            property: "fade"
                            to: win.floating ? 0 : 1
                            duration: win.floating ? 120 : 0
                            easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: card
                            property: "collapse"
                            to: 0
                            duration: Appearance.anim.panel
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.bounce.exit
                        }
                        onFinished: if (card.retireAction) card.retireAction()
                    }

                    readonly property bool last: index === list.count - 1

                    color: Colors.m3surface
                    readonly property bool first: index === 0
                    // Capped at half the card's current height. Left to Qt, a
                    // card shorter than its corners are tall (while it folds
                    // away) kept its bottom corners round and squared off the
                    // top ones; capping them all keeps the shape even.
                    readonly property real cornerRadius: Math.min(Appearance.rounding.large,
                                                                  height / 2)
                    // Floating over a fullscreen window, a leaving card first
                    // fades out, quickly but visibly, and only then folds away
                    // (see exitAnim), so its corners are never seen flattening.
                    // Under the bar it just folds up into it, like the popouts.
                    property real fade: 1
                    opacity: fade
                    topLeftRadius: win.floating && first ? cornerRadius : 0
                    topRightRadius: win.floating && first ? cornerRadius : 0
                    bottomLeftRadius: last ? cornerRadius : 0
                    bottomRightRadius: win.floating && last ? cornerRadius : 0

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

                    ClippingRectangle {
                        visible: card.hasImage
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.leftMargin: Appearance.padding.medium
                        anchors.topMargin: Appearance.padding.medium
                        width: card.imageWidth
                        height: card.imageSize
                        radius: Appearance.rounding.medium
                        Behavior on width {
                            NumberAnimation { duration: Appearance.anim.small; easing.type: Easing.OutCubic }
                        }
                        // Shows while the image is still loading.
                        color: Colors.m3surfaceContainerHigh

                        Image {
                            id: avatar
                            anchors.fill: parent
                            source: card.imageSource
                            fillMode: Image.PreserveAspectCrop
                            // Decoded off the GUI thread, at 2x for sharpness.
                            // Only the height is bounded, so the decoded image
                            // keeps its aspect ratio for imageAspect to read.
                            asynchronous: true
                            sourceSize.height: card.imageSize * 2
                            mipmap: true
                        }
                    }

                    Column {
                        id: content
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: Appearance.padding.medium
                        anchors.leftMargin: Appearance.padding.medium
                                            + (card.hasImage ? card.imageWidth + Appearance.spacing.medium : 0)
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
        }
    }
}
