import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

ShellRoot {
    // one island per monitor
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            WlrLayershell.namespace: "mybar"
            anchors { top: true; left: true; right: true }
            margins { top: 6 }
            implicitHeight: Theme.barHeight
            color: "transparent"
            mask: Region { item: pill }          // clicks outside the island pass through to your windows

            Rectangle {
                id: pill
                anchors.horizontalCenter: parent.horizontalCenter
                height: parent.height
                width: content.implicitWidth + 48
                radius: height / 2
                color: Theme.bg
                border.color: Theme.border
                border.width: 1

                Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

                RowLayout {
                    id: content
                    anchors.centerIn: parent
                    spacing: 20

                    LauncherButton {}
                    Workspaces {}
                    Visualizer { mirrored: true; Layout.leftMargin: 18; Layout.rightMargin: 18 }
                    Clock {}
                    Visualizer { Layout.leftMargin: 18; Layout.rightMargin: 18 }
                    NotifButton {}
                    TasksButton {}
                    Tray {}
                    IdleButton {}
                    WifiButton { screen: modelData }
                    Volume {}
                    PowerButton { screen: modelData }
                }
            }
        }
    }

    TasksWindow {}
    NotifToasts {}
    NotifPanel {}
}
