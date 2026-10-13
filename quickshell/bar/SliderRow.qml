import QtQuick
import QtQuick.Layouts

// icon | slider | percentage.   Used for both sound and brightness.
Item {
    id: root
    property string icon: ""
    property color accent: Theme.accent
    property real value: 0
    property bool spin: false             // rotate the icon with the value (sun)
    signal moved(real v)
    signal iconClicked()

    implicitHeight: 34
    opacity: enabled ? 1 : 0.4
    Behavior on opacity { NumberAnimation { duration: 200 } }
    readonly property bool active: drag.pressed || drag.containsMouse

    RowLayout {
        anchors.fill: parent
        spacing: 12

        // ---- icon ----
        Item {
            id: iconBox
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            scale: iconHit.containsMouse || drag.pressed ? 1.2 : 1
            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

            Text {
                id: glyph
                anchors.centerIn: parent
                text: root.icon
                color: root.accent
                font { family: Theme.iconFont; pixelSize: 20 }
                rotation: root.spin ? root.value * 270 : 0
                Behavior on rotation { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                onTextChanged: pop.restart()       // pops when the icon changes (mute / low / high)
                SequentialAnimation {
                    id: pop
                    NumberAnimation { target: glyph; property: "scale"; to: 1.4; duration: 90; easing.type: Easing.OutQuad }
                    NumberAnimation { target: glyph; property: "scale"; to: 1; duration: 200; easing.type: Easing.OutBack }
                }
            }
            MouseArea {
                id: iconHit
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.iconClicked()
            }
        }

        // ---- slider ----
        Item {
            id: box
            Layout.fillWidth: true
            Layout.preferredHeight: 28

            Rectangle {
                id: groove
                width: parent.width
                height: root.active ? 10 : 6
                radius: height / 2
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.surface
                Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                Rectangle {
                    width: knob.x + knob.width / 2
                    height: parent.height
                    radius: height / 2
                    color: root.accent
                }
            }

            Rectangle {                                    // halo
                anchors.centerIn: knob
                width: 34
                height: 34
                radius: 17
                color: root.accent
                opacity: root.active ? 0.22 : 0
                scale: drag.pressed ? 1.25 : 1
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
            }

            Rectangle {                                    // ripple on press
                id: ripple
                anchors.centerIn: knob
                width: 14
                height: 14
                radius: 7
                color: "transparent"
                border.color: root.accent
                border.width: 2
                opacity: 0
                ParallelAnimation {
                    id: rippleAnim
                    NumberAnimation { target: ripple; property: "scale"; from: 1; to: 3.2; duration: 480; easing.type: Easing.OutCubic }
                    NumberAnimation { target: ripple; property: "opacity"; from: 0.7; to: 0; duration: 480 }
                }
            }

            Rectangle {
                id: knob
                width: 14
                height: 14
                radius: 7
                color: Theme.text
                anchors.verticalCenter: parent.verticalCenter
                x: (parent.width - width) * root.value
                scale: drag.pressed ? 1.4 : (drag.containsMouse ? 1.2 : 1)
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
                Behavior on x { enabled: !drag.pressed; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }

            Rectangle {                                    // floating NN% bubble
                width: 50
                height: 24
                radius: 12
                color: root.accent
                x: knob.x + knob.width / 2 - width / 2
                y: root.active ? -34 : -24
                opacity: root.active ? 1 : 0
                scale: root.active ? 1 : 0.5
                transformOrigin: Item.Bottom
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                Behavior on y       { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Text {
                    anchors.centerIn: parent
                    text: Math.round(root.value * 100) + "%"
                    color: Theme.darkText
                    font { family: "Montserrat"; pixelSize: 12; bold: true }
                }
            }

            MouseArea {
                id: drag
                anchors.fill: parent
                hoverEnabled: true
                function setFrom(m) { root.moved(Math.max(0, Math.min(1, (m.x - knob.width / 2) / (width - knob.width)))) }
                onPressed: m => { rippleAnim.restart(); setFrom(m) }
                onPositionChanged: m => { if (pressed) setFrom(m) }
            }
        }

        Text {
            Layout.preferredWidth: 38
            horizontalAlignment: Text.AlignRight
            text: Math.round(root.value * 100) + "%"
            color: Theme.muted
            font { family: "Montserrat"; pixelSize: 11 }
        }
    }
}
