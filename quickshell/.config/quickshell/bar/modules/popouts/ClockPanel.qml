// Full date and a calendar for the current month.
import QtQuick
import Quickshell
import "root:/"

Column {
    id: root

    spacing: Appearance.spacing.medium

    SystemClock { id: clock; precision: SystemClock.Minutes }

    readonly property date today: clock.date
    readonly property int firstWeekday: new Date(today.getFullYear(), today.getMonth(), 1).getDay()
    readonly property int daysInMonth: new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate()
    readonly property int daysInPrevMonth: new Date(today.getFullYear(), today.getMonth(), 0).getDate()

    Text {
        text: Qt.formatDateTime(root.today, "dddd, d MMMM yyyy")
        color: Colors.m3onSurface
        font.family: Colors.font
        font.pixelSize: Appearance.fontSize.normal
        font.bold: true
    }

    Grid {
        columns: 7
        spacing: 2

        Repeater {
            model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
            delegate: Text {
                required property string modelData
                text: modelData
                color: Colors.teal
                font.family: Colors.font
                font.pixelSize: Appearance.fontSize.small
                horizontalAlignment: Text.AlignHCenter
                width: 24
            }
        }

        Repeater {
            model: 42

            delegate: Item {
                required property int index

                // Which month this cell belongs to, and its date.
                readonly property bool inMonth: index >= root.firstWeekday
                                                && index < root.firstWeekday + root.daysInMonth
                readonly property int day: {
                    if (index < root.firstWeekday)
                        return root.daysInPrevMonth - root.firstWeekday + 1 + index;
                    if (inMonth)
                        return index - root.firstWeekday + 1;
                    return index - root.firstWeekday - root.daysInMonth + 1;
                }
                readonly property bool isToday: inMonth && day === root.today.getDate()

                width: 24
                height: 22

                // Filled disc behind today's date.
                Rectangle {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    radius: width / 2
                    visible: parent.isToday
                    color: Colors.m3primary
                }

                Text {
                    anchors.centerIn: parent
                    text: parent.day
                    color: parent.isToday ? Colors.fg : Colors.m3onSurfaceVariant
                    opacity: parent.inMonth ? 1 : 0.3
                    font.family: Colors.font
                    font.pixelSize: Appearance.fontSize.small
                    font.bold: parent.isToday
                }
            }
        }
    }
}
