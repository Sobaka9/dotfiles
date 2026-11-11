import QtQuick
import Quickshell
import "root:/"

Item {
    id: root

    // 1000-based, the way link speeds are normally quoted.
    function rate(bytesPerSec) {
        const b = bytesPerSec || 0;
        if (b >= 1000000) return (b / 1000000).toFixed(1) + " MB/s";
        if (b >= 1000) return Math.round(b / 1000) + " KB/s";
        return Math.round(b) + " B/s";
    }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Stat {
            icon: Stats.temp >= 80 ? Icons.tempHigh
                  : (Stats.temp >= 60 ? Icons.tempMid : Icons.tempLow)
            value: Stats.temp + "°C"
            // The old waybar config turned this red past 80°C.
            color: Stats.temp >= 80 ? Colors.red : Colors.yellow
        }

        Stat {
            icon: Icons.memory
            value: Stats.mem + "%"
            color: Colors.magenta
        }

        Stat {
            icon: Icons.cpu
            value: Stats.cpu + "%"
            color: Colors.sky
        }

        Stat {
            icon: Stats.online ? Icons.netUp : Icons.netDown
            value: ""
            color: Stats.online ? Colors.blue : Colors.muted
        }
    }

    HitArea {
        onEntered: { Panels.setHovered("system", true); Panels.open("system", root.mapToItem(null, root.width / 2, 0).x, root.QsWindow.window.screen); }
        onExited: { Panels.setHovered("system", false); Panels.cancelPending("system"); }
        onClicked: Panels.hasCurrent ? Panels.close()
                                     : Panels.open("system", root.mapToItem(null, root.width / 2, 0).x, root.QsWindow.window.screen)
    }
}
