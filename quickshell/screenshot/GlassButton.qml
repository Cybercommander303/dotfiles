import QtQuick

Item {
    id: b
    property string text: ""
    property string glyph: "copy"
    property color tint: Config.cyan
    readonly property bool hovered: ma.containsMouse
    signal clicked()

    width: 82
    height: 34

    property real lift: hovered ? -2 : 0
    Behavior on lift { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.01 } }
    transform: Translate { y: b.lift }
    scale: ma.pressed ? 0.94 : 1.0
    Behavior on scale { SpringAnimation { spring: 7; damping: 0.35; epsilon: 0.001 } }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Config.alpha(Config.charcoal, b.hovered ? 0.88 : 0.55)
        border.width: 1
        border.color: b.hovered ? Config.alpha(b.tint, 0.8) : Config.alpha(Config.cyan, 0.2)
        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on border.color { ColorAnimation { duration: 160 } }
    }

    Rectangle {   // underline that opens from the centre
        x: (parent.width - width) / 2
        y: parent.height - 4
        height: 2
        radius: 1
        width: b.hovered ? parent.width * 0.5 : 0
        color: b.tint
        Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
    }

    Item {   // sheen sweep on hover
        anchors.fill: parent
        clip: true
        Rectangle {
            id: sheen
            y: -parent.height * 0.25
            x: -40
            width: 22
            height: parent.height * 1.5
            rotation: 18
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.16) }
                GradientStop { position: 1; color: "transparent" }
            }
        }
    }
    NumberAnimation { id: sheenAnim; target: sheen; property: "x"; from: -40; to: b.width + 20; duration: 520; easing.type: Easing.InOutQuad }
    onHoveredChanged: if (hovered) sheenAnim.restart()

    Rectangle {
        id: ring
        anchors.fill: parent
        radius: 10
        color: "transparent"
        border.width: 1.5
        border.color: b.tint
        opacity: 0
    }
    ParallelAnimation {
        id: ringAnim
        NumberAnimation { target: ring; property: "scale"; from: 1; to: 1.35; duration: 380; easing.type: Easing.OutCubic }
        NumberAnimation { target: ring; property: "opacity"; from: 0.8; to: 0; duration: 380 }
    }
    SequentialAnimation {
        id: popAnim
        NumberAnimation { target: gl; property: "scale"; to: 0.5; duration: 90 }
        NumberAnimation { target: gl; property: "scale"; to: 1; duration: 320; easing.type: Easing.OutBack; easing.overshoot: 2.4 }
    }

    Row {
        anchors.centerIn: parent
        spacing: 7
        Glyph {
            id: gl
            width: 15
            height: 15
            kind: b.glyph
            color: b.hovered ? b.tint : Config.white
        }
        Text {
            height: 15
            verticalAlignment: Text.AlignVCenter
            text: b.text
            color: b.hovered ? Config.white : Config.sub
            font.family: Config.mono
            font.pixelSize: 11
            font.letterSpacing: 0.6
            Behavior on color { ColorAnimation { duration: 160 } }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { ringAnim.restart(); popAnim.restart(); b.clicked(); }
    }
}
