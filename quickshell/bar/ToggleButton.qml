import QtQuick
import QtQuick.Layouts

// kind: 0 = airplane (takes off), 1 = bell (shakes), 2 = moon (rises)
Rectangle {
    id: btn
    property string icon: ""
    property string label: ""
    property color accent: Theme.accent
    property bool active: false
    property int kind: 0
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: 78
    radius: 18
    color: active ? Qt.rgba(accent.r, accent.g, accent.b, 0.24)
                  : (hit.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.1) : Theme.surface)
    border.width: 1
    border.color: active ? accent : (hit.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.55) : Theme.border)
    scale: hit.pressed ? 0.94 : (hit.containsMouse ? 1.05 : 1)
    Behavior on color        { ColorAnimation { duration: 200 } }
    Behavior on border.color { ColorAnimation { duration: 200 } }
    Behavior on scale        { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    onActiveChanged: {
        ring.restart()
        if (kind === 0) fly.restart()
        else if (kind === 1) shake.restart()
        else rise.restart()
    }

    // expanding ring when toggled
    Rectangle {
        id: ringRect
        anchors.centerIn: lift
        width: 30
        height: 30
        radius: 15
        color: "transparent"
        border.width: 2
        border.color: btn.accent
        opacity: 0
    }
    ParallelAnimation {
        id: ring
        NumberAnimation { target: ringRect; property: "scale"; from: 0.6; to: 2.6; duration: 520; easing.type: Easing.OutCubic }
        NumberAnimation { target: ringRect; property: "opacity"; from: 0.7; to: 0; duration: 520 }
    }

    Column {
        anchors.centerIn: parent
        spacing: 9

        Item {
            id: lift                                      // hover: icon lifts and grows a little
            width: 28
            height: 28
            anchors.horizontalCenter: parent.horizontalCenter
            scale: hit.containsMouse ? 1.15 : 1
            transform: Translate { y: hit.containsMouse ? -2 : 0; Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } } }
            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

            Text {
                id: glyph
                anchors.centerIn: parent
                text: btn.icon
                color: btn.active ? btn.accent : Theme.text
                font { family: Theme.iconFont; pixelSize: 22 }
                transformOrigin: btn.kind === 1 ? Item.Top : Item.Center
                transform: Translate { id: tr }
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: btn.label
            color: btn.active ? btn.accent : Theme.muted
            font { family: "Montserrat"; pixelSize: 11; weight: Font.Medium }
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }

    // airplane: flies off to the top right and glides back in from the bottom left
    SequentialAnimation {
        id: fly
        ParallelAnimation {
            NumberAnimation { target: tr; property: "x"; to: 24; duration: 240; easing.type: Easing.InCubic }
            NumberAnimation { target: tr; property: "y"; to: -24; duration: 240; easing.type: Easing.InCubic }
            NumberAnimation { target: glyph; property: "opacity"; to: 0; duration: 240 }
        }
        ScriptAction { script: { tr.x = -24; tr.y = 24 } }
        ParallelAnimation {
            NumberAnimation { target: tr; property: "x"; to: 0; duration: 360; easing.type: Easing.OutBack }
            NumberAnimation { target: tr; property: "y"; to: 0; duration: 360; easing.type: Easing.OutBack }
            NumberAnimation { target: glyph; property: "opacity"; to: 1; duration: 260 }
        }
    }

    // bell: rings from the top
    SequentialAnimation {
        id: shake
        NumberAnimation { target: glyph; property: "rotation"; to: -28; duration: 70 }
        NumberAnimation { target: glyph; property: "rotation"; to: 24; duration: 110 }
        NumberAnimation { target: glyph; property: "rotation"; to: -16; duration: 100 }
        NumberAnimation { target: glyph; property: "rotation"; to: 10; duration: 90 }
        NumberAnimation { target: glyph; property: "rotation"; to: 0; duration: 80 }
    }

    // moon: tips up into place with a pop
    ParallelAnimation {
        id: rise
        NumberAnimation { target: glyph; property: "rotation"; from: -70; to: 0; duration: 450; easing.type: Easing.OutBack }
        SequentialAnimation {
            NumberAnimation { target: glyph; property: "scale"; to: 1.4; duration: 140; easing.type: Easing.OutQuad }
            NumberAnimation { target: glyph; property: "scale"; to: 1; duration: 260; easing.type: Easing.OutBack }
        }
    }

    MouseArea {
        id: hit
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
