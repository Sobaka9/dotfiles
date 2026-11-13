// The launcher, shown as a popout panel: results with the search box beneath
// them. The state it shows (mode, search text, selected row) and what acts on
// it live in Launcher.qml, shared by this panel on every monitor.
import QtQuick
import Quickshell
import Quickshell.Widgets
import "root:/"

Item {
    id: root

    required property var launcher

    readonly property int rowHeight: 60
    readonly property int visibleRows: 8
    readonly property int searchHeight: 46

    // The popout container sizes the surface from implicitHeight, which
    // jumps straight to the new row count, and animates the surface itself.
    // The list and search box follow `shownRows`, animated with the same
    // timing and curve, so they keep pace with the surface instead of
    // jumping ahead of it.
    readonly property int wantRows: Math.max(1, Math.min(visibleRows, list.count))
    property real shownRows: wantRows
    Behavior on shownRows {
        NumberAnimation {
            duration: Appearance.anim.panel
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.curve.expressiveDefaultSpatial
        }
    }

    implicitWidth: launcher.panelWidth - Appearance.padding.large * 2
    implicitHeight: rowHeight * wantRows + Appearance.spacing.small + searchHeight

    Component.onCompleted: search.text = root.launcher.searchText

    Connections {
        target: root.launcher
        function onOpenChanged() {
            if (root.launcher.open)
                search.forceActiveFocus();
        }
        function onViewReset() {
            list.positionViewAtBeginning();
        }
        function onSearchTextChanged() {
            if (search.text !== root.launcher.searchText)
                search.text = root.launcher.searchText;
        }
    }

    ListView {
        id: list

        width: parent.width
        height: root.rowHeight * root.shownRows

        clip: true
        model: ScriptModel {
            values: root.launcher.entries
            onValuesChanged: {
                // Resetting the index is not enough: if it is already 0 no
                // change signal fires, so nothing repositions the view and it
                // stays wherever the previous list left it, which after
                // switching modes looks like the list starting partway down.
                root.launcher.currentIndex = 0;
                list.positionViewAtBeginning();
            }
        }

        Binding {
            target: list
            property: "currentIndex"
            value: root.launcher.currentIndex
        }
        boundsBehavior: Flickable.StopAtBounds

        // Rows slide when the list re-sorts or filters, but are never faded:
        // ListView can leave a row stuck mid-fade when the list changes
        // quickly, which left an invisible row, a gap where an app should be.
        // With no transition touching their opacity, rows can't end up
        // transparent.
        move: Transition {
            NumberAnimation {
                property: "y"
                duration: Appearance.anim.panel
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.curve.expressiveDefaultSpatial
            }
        }

        displaced: Transition {
            NumberAnimation {
                property: "y"
                duration: Appearance.anim.panel
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.curve.expressiveDefaultSpatial
            }
        }

        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

        WheelHandler {
            property int scrollRows: 2

            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: function (event) {
                const dy = event.pixelDelta.y !== 0
                    ? event.pixelDelta.y * scrollRows
                    : (event.angleDelta.y / 120) * root.rowHeight * scrollRows;

                // The top of the content is originY, not 0: it goes negative
                // once items have been inserted ahead of the visible ones.
                // Clamping to 0 leaves the first rows unreachable above the
                // viewport.
                const minY = list.originY;
                const maxY = minY + Math.max(0, list.contentHeight - list.height);
                list.contentY = Math.max(minY, Math.min(maxY, list.contentY - dy));
                event.accepted = true;
            }
        }

        delegate: Rectangle {
            required property var modelData
            required property int index

            readonly property bool selected: index === root.launcher.currentIndex

            width: list.width
            height: root.rowHeight
            radius: Appearance.rounding.medium
            color: selected ? Colors.m3surfaceContainerHigh
                            : (rowMouse.containsMouse ? Colors.m3surfaceContainer : "transparent")

            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Appearance.padding.medium
                anchors.right: parent.right
                anchors.rightMargin: Appearance.padding.medium
                spacing: Appearance.spacing.medium

                ClippingRectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: (modelData.preview || "") !== ""
                    implicitWidth: visible ? 58 : 0
                    implicitHeight: 38
                    radius: Appearance.rounding.small
                    color: "transparent"

                    Image {
                        anchors.fill: parent
                        source: (modelData.preview || "") === "" ? "" : "file://" + modelData.preview
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 116
                    }
                }

                // Emoji rows have no icon name; they show the glyph.
                IconImage {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 38
                    // Decode off the GUI thread; synchronous icon loads were
                    // part of the stall when rows were created.
                    asynchronous: true
                    visible: modelData.kind !== "emoji"
                             && (modelData.preview || "") === ""
                             && (modelData.icon || "") !== ""
                    source: Quickshell.iconPath(modelData.icon || "", true)
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: modelData.kind === "emoji"
                    width: visible ? 38 : 0
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData.key || ""
                    font.family: Colors.font
                    font.pixelSize: 26
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    Text {
                        text: modelData.kind === "emoji"
                              ? (modelData.subtitle || "")
                              : (modelData.title || "")
                        color: Colors.m3onSurface
                        font.family: Colors.font
                        font.pixelSize: Appearance.fontSize.larger
                        elide: Text.ElideRight
                        width: list.width - 90
                    }
                    Text {
                        text: modelData.kind === "emoji" ? "" : (modelData.subtitle || "")
                        visible: text.length > 0
                        color: Colors.m3onSurfaceVariant
                        font.family: Colors.font
                        font.pixelSize: Appearance.fontSize.smaller
                        elide: Text.ElideRight
                        width: list.width - 90
                    }
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                    if (root.launcher.currentIndex === index)
                        root.launcher.launch(modelData);
                    else
                        root.launcher.currentIndex = index;
                }
            }
        }
    }

    // Search field, beneath the results.
    Rectangle {
        id: searchBox
        y: list.height + Appearance.spacing.small
        width: parent.width
        height: root.searchHeight
        radius: Appearance.rounding.full
        color: Colors.m3surfaceContainer

        Row {
            anchors.fill: parent
            anchors.leftMargin: Appearance.padding.medium
            anchors.rightMargin: Appearance.padding.medium
            spacing: Appearance.spacing.small

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.search
                color: Colors.m3onSurfaceVariant
                font.family: Colors.font
                font.pixelSize: Appearance.fontSize.normal
            }

            TextInput {
                id: search
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 40
                color: Colors.m3onSurface
                font.family: Colors.font
                font.pixelSize: Appearance.fontSize.larger
                selectionColor: Colors.m3primary
                selectedTextColor: Colors.fg

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: search.text.length === 0
                    text: root.launcher.placeholder
                    color: Colors.m3outline
                    font: search.font
                }

                // Typing into a launcher opened by hovering pins it, so the
                // pointer drifting off doesn't close it mid-search.
                onTextEdited: {
                    root.launcher.searchText = text;
                    if (text.length > 0)
                        Panels.pinned = true;
                }

                Keys.onEscapePressed: root.launcher.back()
                Keys.onReturnPressed: root.launcher.launch(root.launcher.entries[root.launcher.currentIndex])
                Keys.onEnterPressed: root.launcher.launch(root.launcher.entries[root.launcher.currentIndex])
                Keys.onDownPressed: if (root.launcher.currentIndex < list.count - 1) root.launcher.currentIndex++
                Keys.onUpPressed: if (root.launcher.currentIndex > 0) root.launcher.currentIndex--
            }
        }
    }
}
