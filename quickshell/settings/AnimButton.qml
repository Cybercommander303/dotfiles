import QtQuick

Item {
    id: b
    property string text: ""
    property string icon: "check"        // cross | apply | check
    property color tint: Theme.accent
    property int delay: 0                // ms to let the click animation play before emitting
    signal clicked()

    implicitWidth: 124
    implicitHeight: 42
    width: implicitWidth
    height: implicitHeight

    readonly property bool hovered: ma.containsMouse
    readonly property bool pressed: ma.pressed

    // lift on hover, squash on press
    property real lift: hovered ? -4 : 0
    Behavior on lift { SpringAnimation { spring: 4; damping: 0.28; epsilon: 0.01 } }
    transform: Translate { y: b.lift }
    scale: pressed ? 0.93 : 1.0
    Behavior on scale { SpringAnimation { spring: 6; damping: 0.3; epsilon: 0.001 } }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Theme.panel2
        border.width: 1.5
        border.color: b.hovered ? b.tint : Theme.border
        Behavior on border.color { ColorAnimation { duration: 180 } }
    }

    // tinted glow rising from the bottom
    Rectangle {
        anchors.fill: parent
        radius: 12
        opacity: b.hovered ? (b.pressed ? 1 : 0.85) : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.alpha(b.tint, 0.02) }
            GradientStop { position: 1; color: Theme.alpha(b.tint, 0.38) }
        }
    }

    // underline that springs open from the center
    Rectangle {
        x: (parent.width - width) / 2
        y: parent.height - 8
        height: 3
        radius: 1.5
        width: b.hovered ? parent.width * 0.62 : 0
        color: b.tint
        Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 2 } }
    }

    // particle burst on click
    Item {
        id: burst
        anchors.centerIn: parent
        width: 1
        height: 1
        property real t: 0
        Repeater {
            model: 10
            Rectangle {
                required property int index
                readonly property real a: index * Math.PI / 5
                width: Math.max(1, 6 * (1 - burst.t))
                height: width
                radius: width / 2
                color: b.tint
                x: Math.cos(a) * burst.t * (46 + (index % 2) * 16) - width / 2
                y: Math.sin(a) * burst.t * (30 + (index % 2) * 12) - height / 2
                visible: burst.t > 0 && burst.t < 1
                opacity: 1 - burst.t
            }
        }
    }
    NumberAnimation { id: burstAnim; target: burst; property: "t"; from: 0; to: 1; duration: 600; easing.type: Easing.OutCubic }

    Row {
        anchors.centerIn: parent
        height: 18
        spacing: 9

        Item {
            id: iconBox
            width: 18
            height: 18
            transformOrigin: Item.Center
            property real hop: 0
            property real hx: 0
            transform: Translate { x: iconBox.hx; y: iconBox.hop }

            Icon {
                anchors.fill: parent
                kind: b.icon
                color: b.hovered ? b.tint : Theme.text
                scale: b.hovered ? 1.2 : 1.0
                Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
            }
        }

        Text {
            height: 18
            verticalAlignment: Text.AlignVCenter
            text: b.text
            color: b.hovered ? Theme.text : Theme.sub
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fs
            font.weight: Font.DemiBold
            Behavior on color { ColorAnimation { duration: 160 } }
        }
    }

    // hover: cross shakes, apply does a turn, check hops
    onHoveredChanged: if (hovered) hoverAnim.restart()
    ParallelAnimation {
        id: hoverAnim
        SequentialAnimation {
            NumberAnimation { target: iconBox; property: "hx"; to: b.icon === "cross" ? -4 : 0; duration: 45 }
            NumberAnimation { target: iconBox; property: "hx"; to: b.icon === "cross" ? 4 : 0; duration: 80 }
            NumberAnimation { target: iconBox; property: "hx"; to: b.icon === "cross" ? -3 : 0; duration: 70 }
            NumberAnimation { target: iconBox; property: "hx"; to: b.icon === "cross" ? 3 : 0; duration: 70 }
            NumberAnimation { target: iconBox; property: "hx"; to: 0; duration: 60 }
        }
        SequentialAnimation {
            NumberAnimation { target: iconBox; property: "rotation"; from: 0; to: b.icon === "apply" ? 360 : 0; duration: 700; easing.type: Easing.InOutCubic }
            ScriptAction { script: iconBox.rotation = 0 }
        }
        SequentialAnimation {
            NumberAnimation { target: iconBox; property: "hop"; to: b.icon === "check" ? -6 : 0; duration: 120; easing.type: Easing.OutQuad }
            NumberAnimation { target: iconBox; property: "hop"; to: 0; duration: 380; easing.type: Easing.OutBounce }
        }
    }

    // click: cross implodes, apply spins twice, check pops big
    SequentialAnimation {
        id: clickAnim
        ScriptAction { script: { hoverAnim.stop(); iconBox.rotation = 0; iconBox.hop = 0; iconBox.hx = 0; iconBox.scale = 1; } }
        ParallelAnimation {
            NumberAnimation {
                target: iconBox; property: "rotation"
                to: b.icon === "apply" ? 720 : 0
                duration: 700; easing.type: Easing.OutCubic
            }
            SequentialAnimation {
                NumberAnimation { target: iconBox; property: "scale"; to: b.icon === "check" ? 1.8 : (b.icon === "cross" ? 0.3 : 0.7); duration: 150 }
                NumberAnimation { target: iconBox; property: "scale"; to: 1; duration: 450; easing.type: Easing.OutBack; easing.overshoot: 2.4 }
            }
            SequentialAnimation {
                NumberAnimation { target: iconBox; property: "hop"; to: b.icon === "check" ? -10 : 0; duration: 150; easing.type: Easing.OutQuad }
                NumberAnimation { target: iconBox; property: "hop"; to: 0; duration: 420; easing.type: Easing.OutBounce }
            }
        }
        ScriptAction { script: iconBox.rotation = 0 }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            clickAnim.restart();
            burstAnim.restart();
            if (b.delay > 0) fire.restart(); else b.clicked();
        }
    }
    Timer { id: fire; interval: b.delay; onTriggered: b.clicked() }
}
