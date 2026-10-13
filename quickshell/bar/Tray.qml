import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick

Row {
    spacing: 8
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: item
            required property var modelData
            width: 18
            height: 18
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton) modelData.activate()
                else modelData.secondaryActivate()
            }

            IconImage { anchors.fill: parent; source: item.modelData.icon }
        }
    }
}
