import QtQuick
import Quickshell
import "root:/"

Text {
    id: root

    text: Icons.clock + " " + Qt.formatDateTime(clock.date, "HH:mm")
    color: Colors.m3onSurface
    font.family: Colors.font
    font.pixelSize: Appearance.fontSize.normal
    verticalAlignment: Text.AlignVCenter

    SystemClock { id: clock; precision: SystemClock.Minutes }

    readonly property date today: clock.date
    readonly property int firstWeekday: new Date(today.getFullYear(), today.getMonth(), 1).getDay()
    readonly property int daysInMonth: new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate()

    HitArea {
        onEntered: { Panels.setHovered("clock", true); Panels.open("clock", root.mapToItem(null, root.width / 2, 0).x, root.QsWindow.window.screen); }
        onExited: { Panels.setHovered("clock", false); Panels.cancelPending("clock"); }
        onClicked: Panels.hasCurrent ? Panels.close()
                                     : Panels.open("clock", root.mapToItem(null, root.width / 2, 0).x, root.QsWindow.window.screen)
    }
}
