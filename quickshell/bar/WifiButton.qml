import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

Item {
    id: root
    property var screen
    property bool open: false

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    onOpenChanged: {
        if (open) Wifi.refresh()
        else list.selected = ""
    }

    // rescan while open (but not while someone is picking a network / typing a password)
    Timer {
        interval: 6000
        running: root.open
        repeat: true
        onTriggered: if (list.selected === "") Wifi.refresh()
    }

    // after a connect attempt finishes, fold the row back up
    Connections {
        target: Wifi
        function onBusySsidChanged() { if (Wifi.busySsid === "") list.selected = "" }
    }

    // ---- bar icon ----
    Text {
        id: icon
        text: "\uf1eb"
        color: hit.containsMouse || root.open ? Theme.accent : (Wifi.activeSsid === "" ? Theme.muted : Theme.text)
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
        onClicked: root.open = !root.open
    }

    // ---- the panel ----
    // A PanelWindow (not a PopupWindow) so the password field can receive keyboard input.
    PanelWindow {
        id: panel
        screen: root.screen
        visible: root.open || card.opacity > 0.01

        anchors { top: true }
        margins { top: Theme.barHeight + 14 }
        implicitWidth: 320
        implicitHeight: 470
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "mybar-wifi"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        HyprlandFocusGrab {
            windows: [panel, root.QsWindow.window]     // clicks on the bar itself don't count as "outside"
            active: root.open
            onCleared: root.open = false
        }

        Rectangle {
            id: card
            width: parent.width
            height: parent.height
            radius: Theme.radius + 4
            color: Theme.bg
            border.color: Theme.border
            border.width: 1
            focus: true
            Keys.onEscapePressed: root.open = false

            // slow, smooth open / close
            y: root.open ? 0 : -18
            opacity: root.open ? 1 : 0
            scale: root.open ? 1 : 0.94
            transformOrigin: Item.Top
            Behavior on y       { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

            // ---- rotating globe ----
            Item {
                id: globe
                width: 110
                height: 110
                anchors { top: parent.top; topMargin: 20; horizontalCenter: parent.horizontalCenter }

                Rectangle {                              // soft pulse ring behind the globe
                    id: ring
                    anchors.centerIn: parent
                    width: 96
                    height: 96
                    radius: 48
                    color: "transparent"
                    border.color: Theme.globe
                    border.width: 2

                    ParallelAnimation {
                        running: panel.visible
                        loops: Animation.Infinite
                        NumberAnimation { target: ring; property: "scale"; from: 0.8; to: 1.18; duration: 2000; easing.type: Easing.OutQuad }
                        NumberAnimation { target: ring; property: "opacity"; from: 0.55; to: 0; duration: 2000 }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "\uf0ac"
                    color: Theme.globe
                    font { family: Theme.iconFont; pixelSize: 64 }
                    RotationAnimator on rotation { from: 0; to: 360; duration: 5000; loops: Animation.Infinite; running: panel.visible }
                }
            }

            Text {
                id: subtitle
                anchors { top: globe.bottom; topMargin: 6; horizontalCenter: parent.horizontalCenter }
                text: Wifi.activeSsid === "" ? "Not connected" : "Connected to " + Wifi.activeSsid
                color: Theme.muted
                font { family: Theme.font; pixelSize: 12 }
            }

            // ---- network list ----
            ListView {
                id: list
                property string selected: ""

                anchors {
                    top: subtitle.bottom; topMargin: 14
                    left: parent.left; leftMargin: 16
                    right: parent.right; rightMargin: 16
                    bottom: status.top; bottomMargin: 8
                }
                clip: true
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds
                model: Wifi.networks

                delegate: NetworkRow {
                    required property var modelData
                    net: modelData
                    expanded: list.selected === modelData.ssid
                    onToggled: list.selected = (list.selected === modelData.ssid ? "" : modelData.ssid)
                }

                Text {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    text: "Looking for networks…"
                    color: Theme.muted
                    font { family: Theme.font; pixelSize: 13 }
                }
            }

            // ---- result line (connected / error) ----
            Text {
                id: status
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 16; rightMargin: 16; bottomMargin: 12 }
                height: 16
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                text: Wifi.message
                color: Wifi.failed ? Theme.red : Theme.globe
                opacity: Wifi.message === "" ? 0 : 1
                font { family: Theme.font; pixelSize: 12 }
                Behavior on opacity { NumberAnimation { duration: 250 } }
            }
        }
    }
}
