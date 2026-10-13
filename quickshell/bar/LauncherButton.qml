import Quickshell
import QtQuick

Item {
    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Text {
        id: icon
        text: "\uf00a"
        color: hit.containsMouse ? Theme.accent : Theme.text
        font { family: Theme.iconFont; pixelSize: 16 }
        transformOrigin: Item.Center
        scale: hit.containsMouse ? 1.15 : 1
        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: hit
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        // the launcher is a separate Quickshell instance, so we reach it over IPC
        onClicked: Quickshell.execDetached(["qs", "-c", "launcher", "ipc", "call", "launcher", "toggle"])
    }
}
