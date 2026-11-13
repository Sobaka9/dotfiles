// Today's full date, and a calendar you can page through by month: the
// arrows, scrolling over it, or clicking a dimmed day from a neighbouring
// month. It always reopens on the current month.
import QtQuick
import Quickshell
import "root:/"

Column {
    id: root

    spacing: Appearance.spacing.medium

    SystemClock { id: clock; precision: SystemClock.Minutes }

    readonly property date today: clock.date

    // Months away from today's month; the calendar shows that month.
    property int monthOffset: 0
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + monthOffset, 1)
    readonly property bool showingToday: monthOffset === 0

    readonly property int firstWeekday: shown.getDay()
    readonly property int daysInMonth: new Date(shown.getFullYear(), shown.getMonth() + 1, 0).getDate()
    readonly property int daysInPrevMonth: new Date(shown.getFullYear(), shown.getMonth(), 0).getDate()

    readonly property int cellWidth: 26
    readonly property int cellHeight: 24
    readonly property int gridSpacing: 2
    readonly property int gridWidth: cellWidth * 7 + gridSpacing * 6

    // Slides the grid in from the side it is moving towards.
    function go(delta) {
        if (delta === 0)
            return;
        root.monthOffset += delta;
        slideIn.from = delta > 0 ? 14 : -14;
        slideIn.restart();
    }
    function goToday() {
        root.go(-root.monthOffset);
    }

    // Back to the current month once the panel has gone, not as it goes,
    // so the grid doesn't change under the closing animation.
    Connections {
        target: Panels
        function onHasCurrentChanged() { resetTimer.restart(); }
        function onCurrentNameChanged() { resetTimer.restart(); }
    }
    Timer {
        id: resetTimer
        interval: 600
        onTriggered: if (!(Panels.hasCurrent && Panels.currentName === "clock")) root.monthOffset = 0
    }

    Text {
        id: dateText
        text: Qt.formatDateTime(root.today, "dddd, d MMMM yyyy")
        color: Colors.m3onSurface
        font.family: Colors.font
        font.pixelSize: Appearance.fontSize.normal
        font.bold: true
    }

    // ‹  Month Year        [today] ›
    // The back-to-today button only shows away from the current month, but
    // its space is always kept so nothing shifts when it appears.
    Item {
        width: Math.max(root.gridWidth, dateText.implicitWidth)
        height: 26

        NavButton {
            id: prevButton
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            glyph: Icons.prev
            onActivated: root.go(-1)
        }

        Text {
            anchors.left: prevButton.right
            anchors.leftMargin: Appearance.spacing.small
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(root.shown, "MMMM yyyy")
            color: Colors.m3onSurface
            font.family: Colors.font
            font.pixelSize: Appearance.fontSize.smaller
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Appearance.spacing.extraSmall

            NavButton {
                glyph: Icons.today
                glyphSize: Appearance.fontSize.normal
                opacity: root.showingToday ? 0 : 1
                enabled: !root.showingToday
                Behavior on opacity { NumberAnimation { duration: Appearance.anim.expressiveFastEffects } }
                onActivated: root.goToday()
            }

            NavButton {
                glyph: Icons.next
                onActivated: root.go(1)
            }
        }
    }

    Item {
        width: root.gridWidth
        height: grid.implicitHeight

        // Scrolling over the calendar pages through months.
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: function (event) {
                root.go(event.angleDelta.y > 0 ? -1 : 1);
            }
        }

        Grid {
            id: grid
            columns: 7
            spacing: root.gridSpacing

            property real slide: 0
            transform: Translate { x: grid.slide }
            opacity: 1 - Math.abs(grid.slide) / 20

            NumberAnimation {
                id: slideIn
                target: grid
                property: "slide"
                to: 0
                duration: Appearance.anim.small
                easing.type: Easing.OutCubic
            }

            Repeater {
                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                delegate: Text {
                    required property string modelData
                    text: modelData
                    color: Colors.teal
                    font.family: Colors.font
                    font.pixelSize: Appearance.fontSize.small
                    horizontalAlignment: Text.AlignHCenter
                    width: root.cellWidth
                }
            }

            // Always six weeks, so the panel's size never changes between
            // months.
            Repeater {
                model: 42

                delegate: Item {
                    id: cell
                    required property int index

                    // Which month this cell belongs to (-1, 0 or 1 relative
                    // to the one shown), and its day number.
                    readonly property int monthDelta: index < root.firstWeekday ? -1
                        : index < root.firstWeekday + root.daysInMonth ? 0 : 1
                    readonly property int day: {
                        if (monthDelta < 0)
                            return root.daysInPrevMonth - root.firstWeekday + 1 + index;
                        if (monthDelta === 0)
                            return index - root.firstWeekday + 1;
                        return index - root.firstWeekday - root.daysInMonth + 1;
                    }
                    readonly property bool isToday: monthDelta === 0 && root.showingToday
                                                    && day === root.today.getDate()

                    width: root.cellWidth
                    height: root.cellHeight

                    // Today: filled disc. A dimmed day from a neighbouring
                    // month: soft disc on hover, as clicking it goes there.
                    Rectangle {
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        radius: width / 2
                        color: cell.isToday ? Colors.m3primary : Colors.m3surfaceContainerHigh
                        opacity: cell.isToday ? 1 : (dayMouse.containsMouse && cell.monthDelta !== 0 ? 1 : 0)
                        Behavior on opacity { NumberAnimation { duration: Appearance.anim.expressiveFastEffects } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: cell.day
                        color: cell.isToday ? Colors.fg : Colors.m3onSurfaceVariant
                        opacity: cell.monthDelta === 0 ? 1 : (dayMouse.containsMouse ? 0.7 : 0.3)
                        font.family: Colors.font
                        font.pixelSize: Appearance.fontSize.small
                        font.bold: cell.isToday
                    }

                    MouseArea {
                        id: dayMouse
                        anchors.fill: parent
                        hoverEnabled: cell.monthDelta !== 0
                        cursorShape: cell.monthDelta !== 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.go(cell.monthDelta)
                    }
                }
            }
        }
    }

    // A round chevron button that lights up on hover.
    component NavButton: Item {
        id: nav
        property string glyph: ""
        property int glyphSize: Appearance.fontSize.larger
        signal activated()

        width: 26
        height: 26

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Colors.m3surfaceContainerHigh
            opacity: navMouse.containsMouse ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Appearance.anim.expressiveFastEffects } }
        }

        Text {
            anchors.centerIn: parent
            text: nav.glyph
            color: navMouse.containsMouse ? Colors.m3primary : Colors.m3onSurfaceVariant
            Behavior on color { ColorAnimation { duration: Appearance.anim.expressiveFastEffects } }
            font.family: Colors.font
            font.pixelSize: nav.glyphSize
        }

        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: nav.activated()
        }
    }
}
