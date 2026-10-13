import QtQuick
import QtQuick.Shapes

// A square filled with a radial gradient that fades to transparent = a soft glow.
Shape {
    id: g
    property color glowColor: "white"
    property real size: 130
    width: size
    height: size

    ShapePath {
        strokeWidth: -1
        strokeColor: "transparent"
        fillGradient: RadialGradient {
            centerX: g.size / 2
            centerY: g.size / 2
            centerRadius: g.size / 2
            focalX: g.size / 2
            focalY: g.size / 2
            GradientStop { position: 0.0;  color: Qt.rgba(g.glowColor.r, g.glowColor.g, g.glowColor.b, 0.65) }
            GradientStop { position: 0.55; color: Qt.rgba(g.glowColor.r, g.glowColor.g, g.glowColor.b, 0.22) }
            GradientStop { position: 1.0;  color: Qt.rgba(g.glowColor.r, g.glowColor.g, g.glowColor.b, 0.0) }
        }
        startX: 0; startY: 0
        PathLine { x: g.size; y: 0 }
        PathLine { x: g.size; y: g.size }
        PathLine { x: 0; y: g.size }
        PathLine { x: 0; y: 0 }
    }
}
