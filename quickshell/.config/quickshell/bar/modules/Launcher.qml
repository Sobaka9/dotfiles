// Application launcher

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import "root:/"

Scope {
    id: root

    property bool open: false

    // "apps" by default; ">" switches to the command list, and picking a
    // command switches to that command's own list.
    property string mode: "apps"

    // What the empty search field offers to search.
    readonly property string placeholder: {
        switch (root.mode) {
        case "themes":    return "Search themes";
        case "clipboard": return "Search clipboard";
        case "emoji":     return "Search emoji";
        case "commands":  return "Search commands";
        default:          return "Search applications";
        }
    }

    // Text after the ">" in command mode, or the plain query otherwise.
    readonly property string query: {
        const t = search.text;
        if (root.mode === "commands")
            return t.startsWith(">") ? t.slice(1).trim() : t.trim();
        return t.trim();
    }

    // Each opening starts fresh.
    onOpenChanged: {
        offsetAnim.easing.bezierCurve = root.open ? Appearance.bounce.curve
                                                  : Appearance.bounce.exit;
        win.offsetScale = root.open ? 0 : 1;

        if (root.open) {
            search.forceActiveFocus();
            // Pin to whichever monitor is focused right now, for as long as
            // this opening lasts.
            root.targetScreen = root.focusedScreen();
            root.mode = "apps";
            search.text = "";
            list.currentIndex = 0;
            list.positionViewAtBeginning();
        }
    }

    // Hyprland binds to this by name: `hl.dsp.global("quickshell:launcher")`.
    GlobalShortcut {
        appid: "quickshell"
        name: "launcher"
        description: "Toggle the application launcher"
        onPressed: root.open = !root.open
    }

    function openIn(mode) {
        if (root.open && root.mode === mode) {
            root.open = false;
            return;
        }
        root.open = true;
        root.mode = mode;
        search.text = "";
        list.currentIndex = 0;
        list.positionViewAtBeginning();
        LauncherSources.load(mode);
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "launcher-themes"
        description: "Open the launcher on the theme list"
        onPressed: root.openIn("themes")
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "launcher-clipboard"
        description: "Open the launcher on clipboard history"
        onPressed: root.openIn("clipboard")
    }

    property var targetScreen: null

    function focusedScreen() {
        const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        for (let i = 0; i < Quickshell.screens.length; i++)
            if (Quickshell.screens[i].name === name)
                return Quickshell.screens[i];
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    Component.onCompleted: root.targetScreen = root.focusedScreen()

    readonly property var entries: {
        const q = root.query;

        if (root.mode === "commands")
            return LauncherSources.commands
                .filter(c => q.length === 0
                          || c.title.toLowerCase().includes(q.toLowerCase())
                          || c.id.includes(q.toLowerCase()))
                .map(c => ({ kind: "command", key: c.id, title: c.title,
                             subtitle: c.subtitle, icon: c.icon, mode: c.mode }));

        if (root.mode !== "apps") {
            const src = root.mode === "clipboard" ? LauncherSources.clipboard
                      : root.mode === "themes" ? LauncherSources.themes
                      : LauncherSources.emoji;
            if (q.length === 0) return src;
            const lq = q.toLowerCase();
            return src.filter(i => i.title.toLowerCase().includes(lq)
                                || (i.subtitle || "").toLowerCase().includes(lq));
        }
        const all = DesktopEntries.applications.values.filter(a => !a.noDisplay);
        const asRow = a => ({ kind: "app", key: a.id, title: a.name || "",
                              subtitle: a.comment || a.genericName || "",
                              icon: a.icon, entry: a });

        if (q.length === 0) {
            return all.slice().sort((a, b) => {
                const d = LauncherUsage.countFor(b.id) - LauncherUsage.countFor(a.id);
                return d !== 0 ? d : (a.name || "").localeCompare(b.name || "");
            }).map(asRow);
        }

        const scored = [];
        for (const a of all) {
            const sc = LauncherSearch.score(a, q);
            if (sc >= 0) scored.push({ entry: a, score: sc });
        }
        scored.sort((x, y) => {
            if (y.score !== x.score) return y.score - x.score;
            const d = LauncherUsage.countFor(y.entry.id) - LauncherUsage.countFor(x.entry.id);
            return d !== 0 ? d : (x.entry.name || "").localeCompare(y.entry.name || "");
        });
        return scored.map(x => asRow(x.entry));
    }

    function launch(row) {
        if (!row) return;

        if (row.kind === "command") {
            root.mode = row.mode;
            LauncherSources.load(row.mode);
            search.text = "";
            list.currentIndex = 0;
            return;
        }

        if (row.kind === "app") {
            LauncherUsage.record(row.key);
            row.entry.execute();
        } else {
            LauncherSources.activate(row);
        }
        root.open = false;
    }

    function back() {
        if (root.mode === "apps") {
            root.open = false;
        } else if (root.mode === "commands") {
            root.mode = "apps";
            search.text = "";
        } else {
            root.mode = "commands";
            search.text = ">";
        }
    }

    PanelWindow {
        id: win

        screen: root.targetScreen
        anchors.top: true
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive
                                               : WlrKeyboardFocus.None

        readonly property int corner: Appearance.rounding.large

        readonly property int rowHeight: 60
        readonly property int visibleRows: 8
        readonly property int searchHeight: 46

        readonly property int wantRows: Math.max(1, Math.min(visibleRows, list.count))
        property real shownRows: wantRows
        Behavior on shownRows {
            NumberAnimation {
                duration: Appearance.anim.panel
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.curve.expressiveDefaultSpatial
            }
        }

        function chrome(rows) {
            return Appearance.padding.large * 2
                 + rowHeight * rows
                 + Appearance.spacing.small
                 + searchHeight;
        }

        readonly property real surfaceHeight: chrome(shownRows)

        implicitWidth: 760 + corner * 2
        implicitHeight: chrome(visibleRows) * (1 + Appearance.bounce.overshoot) + Appearance.shadow.margin

        visible: true
        mask: Region {
            x: clipper.x
            y: 0
            width: clipper.height > 0 ? clipper.width : 0
            height: clipper.height
        }

        property real offsetScale: 1
        Behavior on offsetScale {
            NumberAnimation {
                id: offsetAnim
                duration: Appearance.anim.panel
                easing.type: Easing.BezierSpline
            }
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
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: Math.max(0, (win.surfaceHeight + Appearance.shadow.margin) * (1 - win.offsetScale))
                visible: height > 0
                clip: true

                Rectangle {
                    id: surface

                    x: win.corner
                    width: parent.width - win.corner * 2
                    height: Math.max(0, win.surfaceHeight * (1 - win.offsetScale))
                    y: 0

                    color: Colors.m3surface
                    topLeftRadius: 0
                    topRightRadius: 0
                    bottomLeftRadius: Appearance.rounding.extraLarge
                    bottomRightRadius: Appearance.rounding.extraLarge

                    InvertedCorner {
                        anchors.right: parent.left
                        anchors.top: parent.top
                        size: Appearance.rounding.large
                        color: parent.color
                    }

                    InvertedCorner {
                        anchors.left: parent.right
                        anchors.top: parent.top
                        size: Appearance.rounding.large
                        color: parent.color
                        mirrored: true
                    }
                }
            }
        }

        Item {
            x: win.corner + Appearance.padding.large
            y: 0
            width: surface.width - Appearance.padding.large * 2
            height: surface.height
            visible: clipper.height > 0
            clip: true

            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                y: Appearance.padding.large
                height: Math.max(0, win.surfaceHeight - Appearance.padding.large * 2)

                // Results, with the search box beneath them.
                ListView {
                    id: list

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: win.rowHeight * win.shownRows

                    clip: true
                    model: ScriptModel {
                        values: root.entries
                        onValuesChanged: list.currentIndex = 0
                    }

                    currentIndex: 0
                    boundsBehavior: Flickable.StopAtBounds

                    move: Transition {
                        NumberAnimation {
                            property: "y"
                            duration: Appearance.anim.panel
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.curve.expressiveDefaultSpatial
                        }
                        NumberAnimation { property: "opacity"; to: 1; duration: Appearance.anim.small }
                    }

                    displaced: Transition {
                        NumberAnimation {
                            property: "y"
                            duration: Appearance.anim.panel
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.curve.expressiveDefaultSpatial
                        }
                        NumberAnimation { property: "opacity"; to: 1; duration: Appearance.anim.small }
                    }

                    addDisplaced: Transition {
                        NumberAnimation {
                            property: "y"
                            duration: Appearance.anim.panel
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.curve.expressiveDefaultSpatial
                        }
                        NumberAnimation { property: "opacity"; to: 1; duration: Appearance.anim.small }
                    }

                    add: Transition {
                        NumberAnimation {
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: Appearance.anim.small
                            easing.type: Easing.OutCubic
                        }
                    }

                    remove: Transition {
                        NumberAnimation {
                            property: "opacity"
                            from: 1
                            to: 0
                            duration: Appearance.anim.expressiveFastEffects
                            easing.type: Easing.OutCubic
                        }
                    }

                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                    WheelHandler {
                        property int scrollRows: 2

                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: function (event) {
                            const dy = event.pixelDelta.y !== 0
                                ? event.pixelDelta.y * scrollRows
                                : (event.angleDelta.y / 120) * win.rowHeight * scrollRows;

                            const maxY = Math.max(0, list.contentHeight - list.height);
                            list.contentY = Math.max(0, Math.min(maxY, list.contentY - dy));
                            event.accepted = true;
                        }
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        readonly property bool selected: index === list.currentIndex

                        width: list.width
                        height: win.rowHeight
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
                                if (list.currentIndex === index)
                                    root.launch(modelData);
                                else
                                    list.currentIndex = index;
                            }
                        }
                    }
                }

                // Search field, beneath the results.
                Rectangle {
                    id: searchBox
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: win.searchHeight
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
                                text: root.placeholder
                                color: Colors.m3outline
                                font: search.font
                            }

                            // Typing ">" at the start switches to the command list;
                            // clearing it again drops back to applications.
                            onTextChanged: {
                                if (root.mode === "apps" && text.startsWith(">"))
                                    root.mode = "commands";
                                else if (root.mode === "commands" && !text.startsWith(">"))
                                    root.mode = "apps";
                            }

                            // Escape backs out one level at a time, closing only
                            // once there is nothing left to back out of.
                            Keys.onEscapePressed: root.back()
                            Keys.onReturnPressed: root.launch(root.entries[list.currentIndex])
                            Keys.onEnterPressed: root.launch(root.entries[list.currentIndex])
                            Keys.onDownPressed: if (list.currentIndex < list.count - 1) list.currentIndex++
                            Keys.onUpPressed: if (list.currentIndex > 0) list.currentIndex--
                        }
                    }
                }
                    }
}
    }
}
