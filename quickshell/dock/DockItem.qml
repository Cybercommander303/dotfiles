import QtQuick

Item {
    id: it
    property string kind: "grid"            // grid | code | terminal | files | nvim
    property string label: ""
    property color colorA: "#5F6DE3"
    property color colorB: "#3A44A8"
    property int slot: 0                    // position in the dock (staggers the entrance)
    property real pointerX: -1000           // cursor x inside the dock row
    property bool pointerIn: false
    property bool revealed: false
    signal activated()

    width: 56
    height: 56

    readonly property bool hovered: hit.containsMouse
    // 0..1: how close the cursor is to this icon. Neighbours get a smaller share, like a magnifier.
    readonly property real near: pointerIn ? Math.max(0, 1 - Math.abs(pointerX - (x + width / 2)) / 120) : 0
    property real m: near
    Behavior on m { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
    property real jump: 0
    property bool busy: false

    // icons pop in one after another once the dock has risen
    Connections {
        target: DockState
        function onOpenChanged() { it.revealed = false; if (DockState.open) reveal.restart() }
    }
    Timer { id: reveal; interval: 380 + it.slot * 80; onTriggered: it.revealed = true }
    Timer { id: busyTimer; interval: 1500; onTriggered: it.busy = false }

    function launch() {
        ring.restart()
        flash.restart()
        jumpAnim.restart()
        busy = true
        busyTimer.restart()
        activated()
    }

    // ---------- the icon ----------
    Item {
        id: wrap
        anchors.fill: parent
        transformOrigin: Item.Bottom
        scale: it.revealed ? 1 : 0.2
        opacity: it.revealed ? 1 : 0
        transform: Translate { y: -(it.m * 16 + it.jump) }
        Behavior on scale   { NumberAnimation { duration: 420; easing.type: Easing.OutBack } }
        Behavior on opacity { NumberAnimation { duration: 260 } }

        Item {
            id: body
            anchors.fill: parent
            transformOrigin: Item.Bottom
            scale: 1 + 0.5 * it.m * it.m

            Rectangle {                                       // pulse ring on click
                id: ringRect
                anchors.centerIn: parent
                width: 56
                height: 56
                radius: 16
                color: "transparent"
                border.width: 2
                border.color: it.colorA
                opacity: 0
            }
            ParallelAnimation {
                id: ring
                NumberAnimation { target: ringRect; property: "scale"; from: 1; to: 1.7; duration: 520; easing.type: Easing.OutCubic }
                NumberAnimation { target: ringRect; property: "opacity"; from: 0.8; to: 0; duration: 520 }
            }

            Rectangle {
                id: tile
                anchors.fill: parent
                radius: 16
                gradient: Gradient {
                    GradientStop { position: 0; color: it.colorA }
                    GradientStop { position: 1; color: it.colorB }
                }
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, it.hovered ? 0.45 : 0.18)
                Behavior on border.color { ColorAnimation { duration: 200 } }

                Rectangle {                                   // glossy highlight
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 2 }
                    height: parent.height * 0.45
                    radius: 14
                    color: Qt.rgba(1, 1, 1, 0.13)
                }
                Rectangle {                                   // white flash on click
                    id: flashRect
                    anchors.fill: parent
                    radius: 16
                    color: "white"
                    opacity: 0
                }
                NumberAnimation { id: flash; target: flashRect; property: "opacity"; from: 0.55; to: 0; duration: 420; easing.type: Easing.OutCubic }

                Item {
                    id: art
                    anchors.centerIn: parent
                    width: 36
                    height: 36
                    transformOrigin: Item.Center
                    scale: it.hovered ? 1.12 : 1
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                    Loader {
                        anchors.fill: parent
                        sourceComponent: it.kind === "grid" ? gridArt
                                       : it.kind === "code" ? codeArt
                                       : it.kind === "terminal" ? termArt
                                       : it.kind === "files" ? filesArt
                                       : it.kind === "globe" ? globeArt : nvimArt
                    }
                }
            }
        }
    }

    // hop + bounce when selected
    SequentialAnimation {
        id: jumpAnim
        NumberAnimation { target: it; property: "jump"; to: 26; duration: 170; easing.type: Easing.OutQuad }
        NumberAnimation { target: it; property: "jump"; to: 0; duration: 560; easing.type: Easing.OutBounce }
    }

    // ---------- "launching" dot under the icon ----------
    Rectangle {
        id: dot
        width: 6
        height: 6
        radius: 3
        color: "white"
        x: (it.width - width) / 2
        y: it.height + 5
        opacity: it.busy ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        SequentialAnimation on scale {
            running: it.busy
            loops: Animation.Infinite
            NumberAnimation { to: 1.6; duration: 280; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.8; duration: 280; easing.type: Easing.InOutSine }
        }
    }

    // ---------- name bubble ----------
    Rectangle {
        width: tipText.implicitWidth + 22
        height: 26
        radius: 13
        color: Theme.surface
        border.width: 1
        border.color: it.colorA
        x: (it.width - width) / 2
        y: it.hovered ? -42 - it.m * 20 - it.jump : -30
        opacity: it.hovered ? 1 : 0
        scale: it.hovered ? 1 : 0.6
        transformOrigin: Item.Bottom
        Behavior on opacity { NumberAnimation { duration: 160 } }
        Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
        Behavior on y       { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Text {
            id: tipText
            anchors.centerIn: parent
            text: it.label
            color: Theme.text
            font { family: "Montserrat"; pixelSize: 11; weight: Font.DemiBold }
        }
    }

    MouseArea {
        id: hit
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: it.launch()
    }

    // ---------- the artwork, drawn from plain shapes ----------

    // 3x3 dots that ripple diagonally on hover
    Component {
        id: gridArt
        Grid {
            anchors.centerIn: parent
            columns: 3
            spacing: 5
            Repeater {
                model: 9
                Rectangle {
                    id: d
                    required property int index
                    width: 8
                    height: 8
                    radius: 4
                    color: "white"
                    opacity: 0.94
                    SequentialAnimation {
                        id: wave
                        PauseAnimation { duration: (Math.floor(d.index / 3) + d.index % 3) * 55 }
                        NumberAnimation { target: d; property: "scale"; to: 1.6; duration: 110 }
                        NumberAnimation { target: d; property: "scale"; to: 1; duration: 240; easing.type: Easing.OutBack }
                    }
                    Connections { target: it; function onHoveredChanged() { if (it.hovered) wave.restart() } }
                }
            }
        }
    }

    // < / > : the brackets spread apart and the slash leans on hover
    Component {
        id: codeArt
        Row {
            anchors.centerIn: parent
            spacing: it.hovered ? 5 : 0
            Behavior on spacing { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
            Text { text: "<"; color: "white"; font { family: "Montserrat"; pixelSize: 23; bold: true } }
            Text {
                text: "/"
                color: "#9cdcfe"
                rotation: it.hovered ? 16 : 0
                font { family: "Montserrat"; pixelSize: 23; bold: true }
                Behavior on rotation { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
            }
            Text { text: ">"; color: "white"; font { family: "Montserrat"; pixelSize: 23; bold: true } }
        }
    }

    // > with a blinking cursor (blinks faster on hover)
    Component {
        id: termArt
        Item {
            Text {
                id: prompt
                anchors { left: parent.left; leftMargin: 2; verticalCenter: parent.verticalCenter }
                text: ">"
                color: "#a6e3a1"
                font { family: "monospace"; pixelSize: 28; bold: true }
            }
            Rectangle {
                width: 12
                height: 4
                radius: 2
                color: "#a6e3a1"
                anchors { left: prompt.right; leftMargin: 3; bottom: prompt.bottom; bottomMargin: 7 }
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0; duration: it.hovered ? 200 : 520 }
                    NumberAnimation { to: 1; duration: it.hovered ? 200 : 520 }
                }
            }
        }
    }

    // a folder whose front flap swings open on hover
    Component {
        id: filesArt
        Item {
            Rectangle { x: 3; y: 5; width: 14; height: 8; radius: 3; color: "#1e3a8a" }
            Rectangle { x: 3; y: 9; width: 30; height: 23; radius: 4; color: "#1e3a8a" }
            Rectangle {
                id: front
                x: 3
                y: 14
                width: 30
                height: 18
                radius: 4
                color: "#bfdbfe"
                transform: Rotation {
                    origin.x: 0
                    origin.y: front.height
                    axis { x: 1; y: 0; z: 0 }
                    angle: it.hovered ? -30 : 0
                    Behavior on angle { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }
                }
            }
        }
    }

    // a hand-built "N": two green bars and a blue diagonal; the bars shift on hover
    Component {
        id: nvimArt
        Item {
            Rectangle { x: 6;  y: it.hovered ? 1 : 4; width: 6; height: 28; radius: 2; color: "#57A143"; Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutBack } } }
            Rectangle { x: 24; y: it.hovered ? 7 : 4; width: 6; height: 28; radius: 2; color: "#57A143"; Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutBack } } }
            Rectangle { x: 15; y: 1; width: 6; height: 34; radius: 2; color: "#3E93CC"; rotation: -33 }
        }
    }

    // a globe: outline, equator, two latitudes and a meridian that turns (faster on hover)
    Component {
        id: globeArt
        Item {
            id: g
            property real phase: 0
            NumberAnimation on phase { from: 0; to: 6.2832; duration: it.hovered ? 1500 : 7000; loops: Animation.Infinite; running: it.revealed }

            Rectangle { anchors.centerIn: parent; width: 32; height: 32; radius: 16; color: "transparent"; border.width: 2.5; border.color: "white" }
            Rectangle { anchors.centerIn: parent; width: 32; height: 2; color: "white" }
            Rectangle { x: 4.5; y: 8.5; width: 27; height: 2; radius: 1; color: "white"; opacity: 0.85 }
            Rectangle { x: 4.5; y: 25.5; width: 27; height: 2; radius: 1; color: "white"; opacity: 0.85 }
            Rectangle {
                anchors.centerIn: parent
                width: 3 + 17 * Math.abs(Math.cos(g.phase))
                height: 32
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: "white"
            }
        }
    }
}
