import QtQuick
import QtQuick.Shapes
import "root:/"

Shape {
    id: root

    property color color: Colors.m3surface
    property int size: Appearance.rounding.large
    property bool mirrored: false

    implicitWidth: size
    implicitHeight: size
    preferredRendererType: Shape.CurveRenderer

    transform: Scale {
        origin.x: root.width / 2
        xScale: root.mirrored ? -1 : 1
    }

    ShapePath {
        fillColor: root.color
        strokeWidth: 0
        strokeColor: "transparent"

        startX: 0
        startY: 0
        PathLine { x: root.size; y: 0 }
        PathLine { x: root.size; y: root.size }
        PathArc {
            x: 0
            y: 0
            radiusX: root.size
            radiusY: root.size
            direction: PathArc.Counterclockwise
        }
    }
}
