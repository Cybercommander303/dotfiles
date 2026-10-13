import Quickshell
import Quickshell.Hyprland
import QtQuick

Item {
    id: root
    property bool open: false
    readonly property bool on: Idle.enabled     // true = hypridle running = glowing bulb

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    // ---- bar icon: bulb when idle-lock is on, moon when paused ----
    Text {
        id: icon
        text: root.on ? "\uf0eb" : "\uf186"
        color: root.on ? Theme.bulb : Theme.moon
        font { family: Theme.iconFont; pixelSize: 16 }
        transformOrigin: Item.Center
        scale: hit.containsMouse ? 1.15 : 1
        Behavior on color { ColorAnimation { duration: 250 } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: hit
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.open = !root.open
    }

    // ---- popup ----
    PopupWindow {
        id: popup
        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        implicitWidth: 210
        implicitHeight: 210                    // 10px gap + 200px card
        color: "transparent"
        visible: root.open || card.opacity > 0.01

        HyprlandFocusGrab {
            windows: [popup]
            active: root.open
            onCleared: root.open = false
        }

        Rectangle {
            id: card
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                top: parent.top
                topMargin: root.open ? 10 : 0
            }
            radius: Theme.radius + 4
            color: Theme.bg
            border.color: Theme.border
            border.width: 1

            opacity: root.open ? 1 : 0
            scale: root.open ? 1 : 0.9
            transformOrigin: Item.Top
            Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
            Behavior on anchors.topMargin { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }

            property real phase: 0              // one loop drives the glow pulse and the rocking
            NumberAnimation on phase { from: 0; to: 1; duration: 2200; loops: Animation.Infinite; running: popup.visible }

            Item {
                id: stage
                width: 130
                height: 130
                anchors { top: parent.top; topMargin: 14; horizontalCenter: parent.horizontalCenter }

                property real onAmt: root.on ? 1 : 0                 // 1 = bulb, 0 = moon (animated)
                Behavior on onAmt { NumberAnimation { duration: 450; easing.type: Easing.InOutCubic } }
                readonly property real offAmt: 1 - onAmt
                readonly property real swing: Math.sin(card.phase * 6.2832)

                scale: stageHit.containsMouse ? 1.07 : 1
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Glow {
                    anchors.centerIn: parent
                    glowColor: Theme.bulb
                    opacity: stage.onAmt * (0.8 + 0.2 * stage.swing)
                    scale: 1 + 0.08 * stage.swing
                }
                Glow {
                    anchors.centerIn: parent
                    glowColor: Theme.moon
                    opacity: stage.offAmt * (0.55 + 0.1 * stage.swing)
                }

                Text {                                                // glowing bulb
                    anchors.centerIn: parent
                    text: "\uf0eb"
                    color: Theme.bulb
                    font { family: Theme.iconFont; pixelSize: 64 }
                    opacity: stage.onAmt
                    scale: (0.5 + 0.5 * stage.onAmt) * (1 + 0.03 * stage.swing)
                }

                Text {                                                // rocking half moon
                    anchors.centerIn: parent
                    text: "\uf186"
                    color: Theme.moon
                    font { family: Theme.iconFont; pixelSize: 64 }
                    opacity: stage.offAmt
                    scale: 0.5 + 0.5 * stage.offAmt
                    transformOrigin: Item.Bottom
                    rotation: 14 * stage.swing * stage.offAmt
                }

                MouseArea {
                    id: stageHit
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Idle.toggle()
                }
            }

            Column {
                anchors { bottom: parent.bottom; bottomMargin: 14; horizontalCenter: parent.horizontalCenter }
                spacing: 2
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.on ? "Idle lock on" : "Idle lock paused"
                    color: root.on ? Theme.bulb : Theme.moon
                    font { family: Theme.font; pixelSize: 13; bold: true }
                    Behavior on color { ColorAnimation { duration: 250 } }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.on ? "Click the bulb to pause" : "Click the moon to resume"
                    color: Theme.muted
                    font { family: Theme.font; pixelSize: 11 }
                }
            }
        }
    }
}
