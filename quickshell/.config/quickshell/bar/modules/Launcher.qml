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

    // True whenever any part of the launcher is still on screen, including
    // while it retracts. `open` flips the moment closing starts, which is too
    // early for anything that needs to stay put until the panel has actually
    // gone — such as the bar's layer.
    readonly property bool onScreen: win.offsetScale < 1

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

    // Each opening starts fresh, but the list is put back to its default
    // state once the panel has fully retracted (onOnScreenChanged), not here.
    // Rebuilding it blocks the GUI thread for up to ~100ms; doing that after
    // the slide had started made the panel stall and then jump ahead.
    onOpenChanged: {
        if (root.open)
            search.forceActiveFocus();
        else
            root.hoverOpened = false;
        // Started last, so any work above lands before the first frame
        // instead of eating into the animation. Opening uses a gentler curve
        // than the popouts' bounce: it overshoots by ~1% instead of ~9%,
        // which on a panel this tall was a visible lurch.
        offsetAnim.easing.bezierCurve = root.open ? Appearance.curve.expressiveDefaultSpatial
                                                  : Appearance.bounce.exit;
        win.offsetScale = root.open ? 0 : 1;
    }

    onOnScreenChanged: if (!root.onScreen) root.reset("apps")

    // Point the list at `mode`, empty and scrolled to the top. Assigning
    // values that are already set triggers nothing, so this costs nothing
    // when the launcher is already in that state.
    function reset(mode) {
        root.mode = mode;
        search.text = "";
        list.currentIndex = 0;
        list.positionViewAtBeginning();
    }

    // Open on `mode`, on `screen` (default: the focused monitor), pinned there
    // for as long as this opening lasts; an already-open launcher only
    // switches lists. The list is prepared before `open` flips, so a rebuild,
    // when one is needed, finishes before the slide begins.
    function show(mode, screen) {
        if (!root.open)
            root.targetScreen = screen || root.focusedScreen();
        root.reset(mode);
        if (mode !== "apps")
            LauncherSources.load(mode);
        root.open = true;
    }

    // ---- Hover to open ----
    // The middle of the bar, where the window title sits, opens the launcher
    // on that monitor after a short dwell, so sweeping the pointer across the
    // bar doesn't grab the keyboard. A launcher opened this way closes once
    // the pointer has left both that part of the bar and the panel, after the
    // same grace period the popouts use, unless something has been typed into
    // it. One opened from the keyboard is left alone.
    readonly property int panelWidth: 760

    property bool titleHovered: false
    property var hoverScreen: null
    property bool hoverOpened: false
    readonly property bool hovered: titleHovered || clipperHover.hovered || contentHover.hovered

    function setTitleHovered(on, screen) {
        if (on)
            root.hoverScreen = screen;
        root.titleHovered = on;
    }

    onHoveredChanged: {
        if (root.hovered) {
            leaveTimer.stop();
            if (!root.open)
                dwellTimer.restart();
        } else {
            dwellTimer.stop();
            if (root.hoverOpened)
                leaveTimer.restart();
        }
    }

    Timer {
        id: dwellTimer
        interval: 150
        onTriggered: {
            if (!root.titleHovered || root.open)
                return;
            root.show("apps", root.hoverScreen);
            root.hoverOpened = true;
        }
    }

    Timer {
        id: leaveTimer
        interval: 250
        onTriggered: {
            if (root.open && root.hoverOpened && !root.hovered && search.text.length === 0)
                root.open = false;
        }
    }

    // Hyprland binds to this by name: `hl.dsp.global("quickshell:launcher")`.
    GlobalShortcut {
        appid: "quickshell"
        name: "launcher"
        description: "Toggle the application launcher"
        onPressed: {
            if (root.open)
                root.open = false;
            else
                root.show("apps");
        }
    }

    function openIn(mode) {
        if (root.open && root.mode === mode) {
            root.open = false;
            return;
        }
        root.show(mode);
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
        // Overlay rather than the default Top: a fullscreen window renders
        // above Top layers, which is why the launcher was invisible on a
        // workspace with something fullscreened. Overlay sits above it, so
        // nothing has to be unfullscreened or minimised to get at the launcher.
        WlrLayershell.layer: WlrLayer.Overlay
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
        // How much of the panel is showing below the bar.
        // Whole pixels: the panel now moves, and at fractional positions its text
        // (snapped to the pixel grid) and its edges (not snapped) stepped
        // unevenly against each other, which read as jitter.
        readonly property real shownHeight: Math.round(Math.max(0, surfaceHeight * (1 - offsetScale)))

        implicitWidth: root.panelWidth + corner * 2
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

                HoverHandler { id: clipperHover }

                Rectangle {
                    id: surface

                    x: win.corner
                    width: parent.width - win.corner * 2
                    height: win.shownHeight
                    y: 0

                    color: Colors.m3surface
                    topLeftRadius: 0
                    topRightRadius: 0
                    // The fillets and the panel's bottom corners share its height, each
                    // getting at most half, so they always meet on a straight stretch of
                    // side; a full-size fillet beside a short panel left a sliver of
                    // background between them in the last frames of every close.
                    readonly property real fillet: Math.max(0, Math.min(Appearance.rounding.large, height / 2))
                    bottomLeftRadius: Math.max(0, Math.min(Appearance.rounding.extraLarge, height / 2))
                    bottomRightRadius: Math.max(0, Math.min(Appearance.rounding.extraLarge, height / 2))

                    InvertedCorner {
                        anchors.right: parent.left
                        anchors.top: parent.top
                        size: surface.fillet
                        color: parent.color
                    }

                    InvertedCorner {
                        anchors.left: parent.right
                        anchors.top: parent.top
                        size: surface.fillet
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
            height: win.shownHeight
            visible: clipper.height > 0
            clip: true

            HoverHandler { id: contentHover }

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
                        onValuesChanged: {
                            // Resetting currentIndex is not enough: if it is
                            // already 0 no change signal fires, so nothing
                            // repositions the view and it stays wherever the
                            // previous list left it — which after switching
                            // modes looks like the list starting partway down.
                            list.currentIndex = 0;
                            list.positionViewAtBeginning();
                        }
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

                            // The top of the content is originY, not 0 — it goes
                            // negative once items have been inserted ahead of the
                            // visible ones. Clamping to 0 leaves the first rows
                            // unreachable above the viewport.
                            const minY = list.originY;
                            const maxY = minY + Math.max(0, list.contentHeight - list.height);
                            list.contentY = Math.max(minY, Math.min(maxY, list.contentY - dy));
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
                                // Decode off the GUI thread; synchronous icon
                                // loads were part of the stall when rows were
                                // created.
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
