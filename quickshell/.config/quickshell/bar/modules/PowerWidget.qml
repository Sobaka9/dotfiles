import QtQuick
import Quickshell
import Quickshell.Io
import "root:/"

Text {
    id: root

    text: Icons.power
    color: Colors.red
    font.family: Colors.font
    font.pixelSize: Appearance.fontSize.normal
    verticalAlignment: Text.AlignVCenter

    Process {
        id: runner
        command: ["true"]
    }

    function run(action) {
        runner.command = ["sh", "-c",
            "if command -v hyprshutdown >/dev/null; then hyprshutdown -p '" + action + "'; else " + action + "; fi"];
        runner.running = true;
        popup.close();
    }

    HitArea {
        rightSlop: Appearance.spacing.small
        onEntered: { Panels.setHovered("power", true); Panels.open("power", root.mapToItem(null, root.width / 2, 0).x, root.QsWindow.window.screen); }
        onExited: { Panels.setHovered("power", false); Panels.cancelPending("power"); }
        onClicked: Panels.hasCurrent ? Panels.close()
                                     : Panels.open("power", root.mapToItem(null, root.width / 2, 0).x, root.QsWindow.window.screen)
    }
}
