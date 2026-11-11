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

    function open(name, centre, screen) {
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
            root.hasCurrent = false;
            root.pendingName = "";
        }
    }
}
