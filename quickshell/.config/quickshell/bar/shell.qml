// Quickshell bar

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick.Effects
import "modules"

ShellRoot {
    // Notification daemon
    Notifications { }

    // Application launcher
    Launcher { id: launcher }

    Variants {
        // One bar per monitor.
        model: Quickshell.screens

        Scope {
            id: perScreen
            required property var modelData

        PanelWindow {
            id: bar

            screen: perScreen.modelData
            anchors { top: true; left: true; right: true }

            // The launcher sits on the overlay layer so it clears fullscreen
            // windows. The bar is normally Top, which a fullscreen window
            // covers — leaving the launcher floating over a gap where the bar
            // should be. Lift the bar to match, but only on the monitor the
            // launcher opened on, and until it has fully retracted — dropping
            // the bar the instant closing starts makes it vanish behind the
            // fullscreen window while the launcher is still animating away.
            // Its own namespace, so Hyprland layer rules can stack it beneath
            // the panels that hang off it (hypr/windowrule.lua).
            WlrLayershell.namespace: "quickshell-bar"
            // The bar always lives on the overlay layer, above fullscreen
            // windows. Over a fullscreen window it hides its contents and
            // takes no input, unless the launcher is up on this monitor, so
            // showing it there is an ordinary redraw and happens with the
            // launcher's first frame. (It used to switch layers instead, but a
            // layer change only lands with the surface's next frame, and a bar
            // hidden under a fullscreen window isn't asked for any, so it
            // showed up late or not at all.) The panels hanging off it are on
            // the overlay layer too, and a Hyprland layer rule draws the bar
            // beneath them (hypr/windowrule.lua).
            // True only for a window that is really fullscreen. Hyprland's
            // workspace `hasFullscreen` is also set by a maximized window (its
            // fullscreen mode 1), which hid the bar over a maximized browser;
            // the Wayland fullscreen state is only set for real fullscreen.
            readonly property bool fullscreenBelow:
                (Hyprland.monitorFor(perScreen.modelData)?.activeWorkspace?.toplevels.values ?? [])
                    .some(t => t.wayland?.fullscreen ?? false)
            // A popout up on this monitor; over a fullscreen window that can
            // only be the launcher, as the hidden bar can't be hovered.
            readonly property bool popoutHere: popouts.active || popouts.onScreen
            readonly property bool shown: !fullscreenBelow || popoutHere
            WlrLayershell.layer: WlrLayer.Overlay
            Binding { target: bar.contentItem; property: "visible"; value: bar.shown }

            // Room below the bar for the screen-edge corners and the shadow.
            // Only the bar itself takes input: the strip under it overlaps
            // the windows beneath, which must stay clickable.
            implicitHeight: Appearance.barHeight
                            + Math.max(Appearance.rounding.large, Appearance.shadow.margin)
            mask: Region {
                width: bar.shown ? surface.width : 0
                height: bar.shown ? surface.height : 0
            }
            exclusiveZone: Appearance.barHeight
            color: "transparent"

            Item {
                id: barVisual
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

                Rectangle {
                    id: barFill
                    anchors.top: parent.top
                    width: parent.width
                    height: Appearance.barHeight
                    color: Colors.m3surface
                }

                InvertedCorner {
                    anchors.left: parent.left
                    anchors.top: barFill.bottom
                    size: Appearance.rounding.large
                    color: barFill.color
                    mirrored: true
                }

                InvertedCorner {
                    anchors.right: parent.right
                    anchors.top: barFill.bottom
                    size: Appearance.rounding.large
                    color: barFill.color
                }
            }

            Item {
                id: surface
                anchors.top: parent.top
                width: parent.width
                height: Appearance.barHeight
            }

            // ---- left: clock, workspaces ----
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: surface.verticalCenter
                spacing: 12

                ClockWidget { anchors.verticalCenter: surface.verticalCenter }

                Workspaces {
                    anchors.verticalCenter: surface.verticalCenter
                    monitorName: perScreen.modelData.name
                }

                Tray { anchors.verticalCenter: surface.verticalCenter }
            }

            // ---- centre: focused window ----
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: surface.verticalCenter
                width: Math.min(implicitWidth, bar.width * 0.4)
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
                color: Colors.m3onSurface
                font.family: Colors.font
                font.pixelSize: Appearance.fontSize.normal
            }

            // Hovering the middle of the bar opens the launcher, which hangs
            // from exactly this stretch of it (Launcher.panelWidth).
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: surface.top
                width: launcher.panelWidth
                height: Appearance.barHeight

                HoverHandler {
                    onHoveredChanged: launcher.setTitleHovered(hovered, perScreen.modelData)
                }
            }

            // ---- right: stats, power ----
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: surface.verticalCenter
                spacing: 0

                AudioWidget { }

                SystemWidget { }

                PowerWidget { }
            }
        }

            // One popout container per monitor, shared by every widget.
            Popouts {
                id: popouts
                targetScreen: perScreen.modelData
                launcherState: launcher
            }
        }
    }
}
