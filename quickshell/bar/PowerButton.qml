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

    function run(cmd) {
        root.open = false
        Quickshell.execDetached(cmd)
    }

    // ---- bar icon ----
    Text {
        id: icon
        text: "\uf011"
        color: hit.containsMouse || root.open ? Theme.shutdown : Theme.text
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

    // ---- panel: only the right edge is anchored, so it sits vertically centred ----
    PanelWindow {
        id: panel
        screen: root.screen
        visible: root.open || card.opacity > 0.01

        anchors { right: true }
        margins { right: 16 }
        implicitWidth: 260
        implicitHeight: 260
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "mybar-power"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        HyprlandFocusGrab {
            windows: [panel, root.QsWindow.window]
            active: root.open
            onCleared: root.open = false
        }

        Rectangle {
            id: card
            width: parent.width
            height: parent.height
            radius: Theme.radius + 6
            color: Theme.bg
            border.color: Theme.border
            border.width: 1
            focus: true
            Keys.onEscapePressed: root.open = false

            // slides in from the right edge while fading and scaling up
            x: root.open ? 0 : 50
            opacity: root.open ? 1 : 0
            scale: root.open ? 1 : 0.92
            transformOrigin: Item.Right
            Behavior on x       { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

            Grid {
                anchors.centerIn: parent
                columns: 2
                spacing: 12

                PowerAction { icon: "\uf011"; label: "Shutdown"; accent: Theme.shutdown; onActivated: root.run(["systemctl", "poweroff"]) }
                PowerAction { icon: "\uf021"; label: "Restart";  accent: Theme.restart;  onActivated: root.run(["systemctl", "reboot"]) }
                PowerAction { icon: "\uf186"; label: "Sleep";    accent: Theme.sleep;    onActivated: root.run(["systemctl", "suspend"]) }
                PowerAction { icon: "\uf023"; label: "Lock";     accent: Theme.lock;     onActivated: root.run(["sh", "-c", "pidof hyprlock || hyprlock"]) }
            }
        }
    }
}
