// Which popout is showing, and where along the bar it should sit.

pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property string currentName: ""
    property real currentCenter: 0
    property var currentScreen: null
    property bool hasCurrent: false

    property var trayItem: null

    property string pendingName: ""
    property real pendingCentre: 0
    property var pendingScreen: null

    // A pinned panel ignores hover: it doesn't close when the pointer leaves,
    // and the pointer passing over another widget doesn't swap it for that
    // widget's panel. Used by the launcher when opened from the keyboard or
    // typed into. Closing, or clicking a widget, still works.
    property bool pinned: false

    function open(name, centre, screen) {
        if (root.pinned && root.hasCurrent && root.currentName !== name)
            return;
        closeTimer.stop();

        if (!root.hasCurrent || root.currentName === name) {
            root.apply(name, centre, screen);
            return;
        }

        root.pendingName = name;
        root.pendingCentre = centre;
        root.pendingScreen = screen;
        switchTimer.restart();
    }

    function apply(name, centre, screen) {
        switchTimer.stop();
        closeTimer.stop();
        root.pendingName = "";
        root.currentName = name;
        root.currentCenter = centre;
        root.currentScreen = screen;
        root.hasCurrent = true;
    }

    property var hovered: ({})

    function setHovered(id, on) {
        const next = Object.assign({}, root.hovered);
        if (on)
            next[id] = true;
        else
            delete next[id];
        root.hovered = next;

        if (Object.keys(next).length > 0) {
            closeTimer.stop();
        } else {
            closeTimer.restart();
        }
    }

    function cancelPending(name) {
        if (name !== undefined && root.pendingName === name) {
            switchTimer.stop();
            root.pendingName = "";
        }
    }

    function keepOpen() {
        closeTimer.stop();
        switchTimer.stop();
        root.pendingName = "";
    }
    function close() {
        closeTimer.stop();
        root.hovered = ({});
        root.hasCurrent = false;
        root.pinned = false;
    }

    Timer {
        id: switchTimer
        interval: 110
        onTriggered: if (root.pendingName !== "")
            root.apply(root.pendingName, root.pendingCentre, root.pendingScreen)
    }

    Timer {
        id: closeTimer
        interval: 250
        onTriggered: {
            if (root.pinned)
                return;
            root.hasCurrent = false;
            root.pendingName = "";
        }
    }
}
