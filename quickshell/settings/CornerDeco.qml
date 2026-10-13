import QtQuick
import QtQuick.Shapes

// Triple concentric arcs hugging a corner + an orbiting dot.
// corner: 0 TL, 1 TR, 2 BR, 3 BL. `energy` (0..1) lengthens the arcs and wakes the dot.
Item {
    id: d
    property int corner: 0
    property real energy: 0
    readonly property int s: 64

    width: s
    height: s
    rotation: corner * 90

    Behavior on energy { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    // arcs are centered on the inner corner point (s, s)
    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            strokeColor: Theme.alpha(Theme.accent, 0.55 + 0.45 * d.energy)
            strokeWidth: 3
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: d.s; centerY: d.s; radiusX: d.s - 4; radiusY: d.s - 4
                sweepAngle: 50 + 40 * d.energy
                startAngle: 180 + (90 - sweepAngle) / 2
            }
        }
        ShapePath {
            strokeColor: Theme.alpha(Theme.accent2, 0.45 + 0.5 * d.energy)
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: d.s; centerY: d.s; radiusX: d.s - 15; radiusY: d.s - 15
                sweepAngle: 34 + 40 * d.energy
                startAngle: 180 + (90 - sweepAngle) / 2
            }
        }
        ShapePath {
            strokeColor: Theme.alpha(Theme.text, 0.2 + 0.4 * d.energy)
            strokeWidth: 1.2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: d.s; centerY: d.s; radiusX: d.s - 25; radiusY: d.s - 25
                sweepAngle: 20 + 36 * d.energy
                startAngle: 180 + (90 - sweepAngle) / 2
            }
        }
    }

    // dot sliding along the outer arc
    Rectangle {
        id: dot
        property real ang: 180
        width: 7
        height: 7
        radius: 3.5
        color: Theme.accent2
        scale: 1 + 0.9 * d.energy
        x: d.s + (d.s - 4) * Math.cos(ang * Math.PI / 180) - width / 2
        y: d.s + (d.s - 4) * Math.sin(ang * Math.PI / 180) - height / 2
        SequentialAnimation on ang {
            loops: Animation.Infinite
            NumberAnimation { to: 270; duration: 2400; easing.type: Easing.InOutSine }
            NumberAnimation { to: 180; duration: 2400; easing.type: Easing.InOutSine }
        }
    }
}
