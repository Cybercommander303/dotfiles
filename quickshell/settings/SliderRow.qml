import QtQuick

Item {
    id: r
    property string label: ""
    property string key: ""
    property real from: 0
    property real to: 100
    property real step: 1
    property int decimals: 0
    property string suffix: ""

    readonly property real value: HyprSettings[key]
    readonly property real frac: Math.max(0, Math.min(1, (value - from) / (to - from)))
    readonly property bool hot: rowHover.hovered || ma.pressed

    width: parent ? parent.width : 300
    height: 40

    HoverHandler { id: rowHover }

    Rectangle {   // row highlight
        anchors.fill: parent
        radius: 10
        color: Theme.alpha(Theme.text, r.hot ? 0.045 : 0)
        Behavior on color { ColorAnimation { duration: 160 } }
    }
    Rectangle {   // accent tick that grows in on hover
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        radius: 1.5
        height: r.hot ? 20 : 0
        color: Theme.accent
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
    }

    Text {
        x: 14
        width: Theme.labelW - 14
        height: parent.height
        verticalAlignment: Text.AlignVCenter
        text: r.label
        color: r.hot ? Theme.text : Theme.sub
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fs
        Behavior on color { ColorAnimation { duration: 160 } }
    }

    Item {
        id: track
        x: Theme.labelW
        width: r.width - Theme.labelW - 64
        height: r.height

        Rectangle {
            id: groove
            width: parent.width
            height: 6
            radius: 3
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.panel2

            Rectangle {
                width: groove.width * r.frac
                height: parent.height
                radius: 3
                Behavior on width { NumberAnimation { duration: 70 } }
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Theme.accent }
                    GradientStop { position: 1; color: Theme.accent2 }
                }
            }
        }

        Rectangle {   // glow halo
            width: handle.width + 14
            height: width
            radius: width / 2
            x: handle.x + handle.width / 2 - width / 2
            y: handle.y + handle.height / 2 - height / 2
            color: Theme.alpha(Theme.accent2, 0.25)
            opacity: ma.pressed ? 1 : (ma.containsMouse ? 0.5 : 0)
            scale: ma.pressed ? 1 : 0.6
            Behavior on opacity { NumberAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
        }

        Rectangle {
            id: handle
            width: ma.pressed ? 20 : (ma.containsMouse ? 18 : 14)
            height: width
            radius: width / 2
            color: Theme.text
            border.width: 3
            border.color: Theme.accent
            y: (parent.height - height) / 2
            x: groove.width * r.frac - width / 2
            Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
            Behavior on x { NumberAnimation { duration: 70 } }
        }

        Rectangle {   // value bubble while dragging
            width: bubbleText.width + 16
            height: 24
            radius: 8
            color: Theme.accent
            x: handle.x + handle.width / 2 - width / 2
            y: handle.y - height - (ma.pressed ? 6 : 0)
            opacity: ma.pressed ? 1 : 0
            scale: ma.pressed ? 1 : 0.4
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
            Behavior on opacity { NumberAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
            Text {
                id: bubbleText
                anchors.centerIn: parent
                text: r.value.toFixed(r.decimals) + r.suffix
                color: Theme.bg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fsSmall
                font.weight: Font.Bold
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            function setFrom(mx) {
                var t = Math.max(0, Math.min(1, mx / track.width));
                var v = Math.round((r.from + t * (r.to - r.from)) / r.step) * r.step;
                v = Math.max(r.from, Math.min(r.to, v));
                HyprSettings[r.key] = Number(v.toFixed(3));
            }
            onPressed: mouse => setFrom(mouse.x)
            onPositionChanged: mouse => { if (pressed) setFrom(mouse.x); }
        }
    }

    Text {
        x: r.width - 60
        width: 56
        height: parent.height
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        text: r.value.toFixed(r.decimals) + r.suffix
        color: Theme.accent2
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fs
        font.weight: Font.DemiBold
    }
}
