import Quickshell.Hyprland
import QtQuick

Row {
    id: root
    spacing: 8

    function has(id) {
        const v = Hyprland.workspaces.values
        for (let i = 0; i < v.length; i++) if (v[i].id === id) return true
        return false
    }

    // always show 1-4, plus any higher workspace that currently exists
    readonly property var ids: {
        const out = [1, 2, 3, 4]
        const v = Hyprland.workspaces.values
        for (let i = 0; i < v.length; i++)
            if (v[i].id > 4 && out.indexOf(v[i].id) < 0) out.push(v[i].id)
        return out.sort((a, b) => a - b)
    }

    Repeater {
        model: root.ids

        Rectangle {
            id: dot
            required property int modelData
            readonly property bool focused: !!Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === modelData
            readonly property bool occupied: root.has(modelData)

            width: focused ? 28 : 18
            height: 18
            radius: 9
            color: focused ? Theme.accent : (occupied ? Theme.surface : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45))

            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 180 } }

            Text {
                anchors.centerIn: parent
                text: dot.modelData
                color: dot.focused ? Theme.darkText : (dot.occupied ? Theme.text : Theme.muted)
                font { family: Theme.font; pixelSize: 11; bold: true }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + dot.modelData)
            }
        }
    }
}
