import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property real vol: audio ? audio.volume : 0
    readonly property bool muted: !audio || audio.muted || vol === 0

    property bool open: false

    implicitWidth: barIcon.implicitWidth
    implicitHeight: barIcon.implicitHeight

    PwObjectTracker { objects: [root.sink] }

    function setVolume(v) {
        if (!audio) return
        audio.volume = Math.max(0, Math.min(1, v))
        if (audio.volume > 0) audio.muted = false
    }

    // ---- bar icon ----
    Text {
        id: barIcon
        text: root.muted ? "\uf026" : root.vol < 0.5 ? "\uf027" : "\uf028"
        color: root.muted ? Theme.muted : (hit.containsMouse || root.open ? Theme.accent : Theme.text)
        font { family: Theme.iconFont; pixelSize: 16 }
        transformOrigin: Item.Center

        Behavior on color { ColorAnimation { duration: 150 } }

        onTextChanged: pop.restart()
        SequentialAnimation {
            id: pop
            NumberAnimation { target: barIcon; property: "scale"; to: 1.3; duration: 90; easing.type: Easing.OutQuad }
            NumberAnimation { target: barIcon; property: "scale"; to: 1.0; duration: 180; easing.type: Easing.OutBack }
        }
    }

    MouseArea {
        id: hit
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.open = !root.open
        onWheel: wheel => root.setVolume(root.vol + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))
    }

    // ---- popup ----
    PopupWindow {
        id: popup
        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        implicitWidth: 280
        implicitHeight: 214                    // 10px transparent gap + 204px card
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

            Behavior on opacity   { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on scale     { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
            Behavior on anchors.topMargin { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            // ---- speaker with sound waves ----
            Speaker {
                anchors { top: parent.top; topMargin: 14; horizontalCenter: parent.horizontalCenter }
                level: root.vol
                muted: root.muted
            }

            // ---- mute icon | slider | max icon ----
            RowLayout {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 20; rightMargin: 20; bottomMargin: 22 }
                height: 28
                spacing: 12

                Text {
                    text: "\uf026"
                    color: root.muted ? Theme.red : Theme.muted
                    font { family: Theme.iconFont; pixelSize: 16 }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: if (root.audio) root.audio.muted = !root.audio.muted
                    }
                }

                Item {
                    id: sliderBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    readonly property bool active: drag.pressed || drag.containsMouse

                    // groove + fill
                    Rectangle {
                        id: groove
                        width: parent.width
                        height: sliderBox.active ? 10 : 6
                        radius: height / 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.surface
                        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                        Rectangle {
                            width: knob.x + knob.width / 2
                            height: parent.height
                            radius: height / 2
                            color: root.muted ? Theme.muted : (sliderBox.active ? Theme.wave : Theme.accent)
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }

                    // soft halo that follows the knob
                    Rectangle {
                        anchors.centerIn: knob
                        width: 34
                        height: 34
                        radius: 17
                        color: Theme.wave
                        opacity: sliderBox.active ? 0.22 : 0
                        scale: drag.pressed ? 1.25 : 1
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    }

                    // ripple that bursts out of the knob when you press
                    Rectangle {
                        id: ripple
                        anchors.centerIn: knob
                        width: 14
                        height: 14
                        radius: 7
                        color: "transparent"
                        border.color: Theme.wave
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
                        x: (parent.width - width) * root.vol

                        scale: drag.pressed ? 1.4 : (drag.containsMouse ? 1.2 : 1)
                        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
                        Behavior on x {
                            enabled: !drag.pressed
                            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                        }
                    }

                    // floating "NN%" bubble above the knob
                    Rectangle {
                        id: bubble
                        width: 50
                        height: 24
                        radius: 12
                        color: Theme.wave
                        x: knob.x + knob.width / 2 - width / 2
                        y: sliderBox.active ? -36 : -26
                        opacity: sliderBox.active ? 1 : 0
                        scale: sliderBox.active ? 1 : 0.5
                        transformOrigin: Item.Bottom
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                        Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                        Behavior on y       { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                        Text {
                            anchors.centerIn: parent
                            text: Math.round(root.vol * 100) + "%"
                            color: "white"
                            font { family: Theme.numFont; pixelSize: 12; bold: true }
                        }
                    }

                    MouseArea {
                        id: drag
                        anchors.fill: parent
                        hoverEnabled: true
                        onPressed: m => {
                            rippleAnim.restart()
                            root.setVolume((m.x - knob.width / 2) / (width - knob.width))
                        }
                        onPositionChanged: m => { if (pressed) root.setVolume((m.x - knob.width / 2) / (width - knob.width)) }
                    }
                }

                Text {
                    text: "\uf028"
                    color: root.vol > 0.95 ? Theme.accent : Theme.muted
                    font { family: Theme.iconFont; pixelSize: 16 }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }
    }
}
