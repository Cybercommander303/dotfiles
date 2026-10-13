import QtQuick

Item {
    id: r
    property string label: ""
    property string key: ""
    readonly property bool on: HyprSettings[key]
    readonly property bool hot: rowHover.hovered

    width: parent ? parent.width : 300
    height: 40

    HoverHandler { id: rowHover }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Theme.alpha(Theme.text, r.hot ? 0.045 : 0)
        Behavior on color { ColorAnimation { duration: 160 } }
    }
    Rectangle {
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

    Rectangle {
        id: pill
        x: Theme.labelW
        anchors.verticalCenter: parent.verticalCenter
        width: 50
        height: 26
        radius: 13
        color: r.on ? Theme.accent : Theme.panel2
        border.width: 1.5
        border.color: r.on ? Theme.accent : Theme.border
        Behavior on color { ColorAnimation { duration: 220 } }

        Rectangle {
            id: knob
            width: ma.pressed ? 26 : 18
            height: 18
            radius: 9
            y: 4
            x: r.on ? pill.width - width - 4 : 4
            color: r.on ? Theme.bg : Theme.sub
            Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.8 } }
            Behavior on width { NumberAnimation { duration: 110 } }
            Behavior on color { ColorAnimation { duration: 220 } }
        }
    }

    Rectangle {   // pulse ring on toggle
        id: ring
        x: pill.x
        y: pill.y
        width: pill.width
        height: pill.height
        radius: 13
        color: "transparent"
        border.width: 2
        border.color: Theme.accent
        opacity: 0
    }
    ParallelAnimation {
        id: ringAnim
        NumberAnimation { target: ring; property: "scale"; from: 1; to: 1.5; duration: 420; easing.type: Easing.OutCubic }
        NumberAnimation { target: ring; property: "opacity"; from: 0.8; to: 0; duration: 420 }
    }

    Text {
        x: pill.x + pill.width + 12
        height: parent.height
        verticalAlignment: Text.AlignVCenter
        text: r.on ? "On" : "Off"
        color: r.on ? Theme.accent2 : Theme.sub
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fs
        font.weight: Font.DemiBold
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: { HyprSettings[r.key] = !r.on; ringAnim.restart(); }
    }
}
