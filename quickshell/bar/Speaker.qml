import QtQuick
import QtQuick.Shapes

// A speaker glyph with sound waves that radiate out of it.
// level: 0..1 (louder = stronger, thicker waves)   muted: stops the waves
Item {
    id: sp
    property real level: 0
    property bool muted: false
    property int size: 64                               // same glyph size as the Wi-Fi globe
    readonly property real maxR: 46
    readonly property real intensity: (!muted && level > 0) ? 0.35 + 0.65 * level : 0

    // where the waves start, measured from the glyph's right edge (tweak if they look off-centre)
    property real originOffset: -4

    property real phase: 0                              // 0..1, loops forever; every wave derives from it
    NumberAnimation on phase {
        from: 0; to: 1; duration: 2100
        loops: Animation.Infinite
        running: sp.visible && Math.max(sp.intensity, fade.value) > 0.01
    }
    // smooth fade when waves start or stop
    QtObject { id: fade; property real value: sp.intensity; Behavior on value { NumberAnimation { duration: 300 } } }

    implicitWidth: 14 + body.implicitWidth + maxR + 10
    implicitHeight: 84

    Text {
        id: body
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        text: "\uf026"
        color: sp.muted ? Theme.muted : Theme.text
        font { family: Theme.iconFont; pixelSize: sp.size }
        transformOrigin: Item.Center
        scale: 1 + 0.035 * fade.value * Math.sin(sp.phase * 6.2832 * 3)   // tiny "thump"
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    Repeater {
        model: 3

        Shape {
            id: wave
            required property int index
            readonly property real p: (sp.phase + index / 3) % 1      // this wave's progress, 0 -> 1
            readonly property real r: 10 + p * (sp.maxR - 10)

            x: body.x + body.implicitWidth + sp.originOffset
            y: (sp.height - height) / 2
            width: sp.maxR
            height: sp.maxR * 2
            antialiasing: true
            opacity: fade.value * Math.min(p * 6, 1) * (1 - p)       // quick fade-in, slow fade-out

            ShapePath {
                strokeColor: Theme.wave
                strokeWidth: 2 + 2 * sp.level
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: 0
                    centerY: wave.height / 2
                    radiusX: wave.r
                    radiusY: wave.r
                    startAngle: -42
                    sweepAngle: 84
                }
            }
        }
    }
}
