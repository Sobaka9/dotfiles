// Design tokens borrowed from the Caelestia dotfiles' shell (caelestia-dots/shell).

pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // Height of the top bar; the notification stack hangs off it.
    readonly property int barHeight: 30

    // Corner radii. `full` is a pill: use it on anything you want fully round.
    readonly property QtObject rounding: QtObject {
        readonly property int extraSmall: 4
        readonly property int small: 8
        readonly property int medium: 12
        readonly property int large: 16
        readonly property int largeIncreased: 20
        readonly property int extraLarge: 28
        readonly property int extraLargeIncreased: 32
        readonly property int extraExtraLarge: 48
        readonly property int full: 1000
    }

    readonly property QtObject spacing: QtObject {
        readonly property int extraSmall: 4
        readonly property int small: 8
        readonly property int medium: 12
        readonly property int large: 16
        readonly property int largeIncreased: 20
        readonly property int extraLarge: 28
        readonly property int extraLargeIncreased: 32
    }

    readonly property QtObject padding: QtObject {
        readonly property int extraSmall: 4
        readonly property int small: 8
        readonly property int medium: 12
        readonly property int large: 16
        readonly property int largeIncreased: 20
        readonly property int extraLarge: 28
    }

    readonly property QtObject fontSize: QtObject {
        readonly property int small: 11
        readonly property int smaller: 12
        readonly property int normal: 13
        readonly property int larger: 15
        readonly property int large: 18
        readonly property int extraLarge: 28
    }

    readonly property QtObject bounce: QtObject {
        readonly property list<real> curve: [0.42, 1.67, 0.31, 0.9, 1, 1]
        readonly property real overshoot: 0.1  // headroom to leave for the above

        readonly property list<real> exit: [0, 0, 0, 1, 1, 1]
    }

    // Drop shadow under the bar and its panels.
    readonly property QtObject shadow: QtObject {
        readonly property int margin: 14
        readonly property real blur: 0.75
        readonly property real opacity: 0.45
        readonly property int yOffset: 2
    }

    readonly property QtObject anim: QtObject {
        readonly property int small: 200
        readonly property int normal: 400
        readonly property int large: 600
        readonly property int expressiveFastSpatial: 350
        readonly property int panel: 230
        readonly property int expressiveDefaultSpatial: 500
        readonly property int expressiveFastEffects: 150
        readonly property int expressiveDefaultEffects: 200
    }

    readonly property QtObject curve: QtObject {
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
        readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property list<real> emphasizedAccel: [0.2, 0, 0.8, 0.15, 1, 1]
        readonly property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
        readonly property list<real> expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
        readonly property list<real> expressiveDefaultEffects: [0.34, 0.8, 0.34, 1, 1, 1]
    }
}
