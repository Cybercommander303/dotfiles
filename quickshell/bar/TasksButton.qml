import QtQuick

Item {
    id: root
    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    // soft highlight pill behind the icon while the window is open
    Rectangle {
        anchors.centerIn: parent
        width: icon.implicitWidth + 16
        height: 26
        radius: 9
        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, TaskState.open ? 0.2 : 0)
        border.width: 1
        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, TaskState.open ? 0.6 : 0)
        Behavior on color        { ColorAnimation { duration: 220 } }
        Behavior on border.color { ColorAnimation { duration: 220 } }
    }

    Text {
        id: icon
        text: "\uf0ae"
        color: TaskState.open || hit.containsMouse ? Theme.accent : Theme.text
        font { family: Theme.iconFont; pixelSize: 16 }
        transformOrigin: Item.Center
        scale: hit.containsMouse ? 1.15 : 1
        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }

    // dot that shows there is something left to do
    Rectangle {
        x: icon.implicitWidth - 3
        y: -3
        width: 8
        height: 8
        radius: 4
        color: Theme.bulb
        border.width: 1
        border.color: Theme.bg
        scale: TaskState.pending > 0 ? 1 : 0
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
    }

    MouseArea {
        id: hit
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: TaskState.open = !TaskState.open
    }
}
