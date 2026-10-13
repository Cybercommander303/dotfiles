import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        readonly property int gap: 14                          // space between the dock and the bottom of the screen
        readonly property bool here: DockState.screenName !== ""
            ? DockState.screenName === modelData.name
            : (!Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === modelData.name)
        visible: here && (DockState.open || pill.y < win.height)

        anchors { bottom: true }                              // only the bottom edge, so it sits in the middle
        implicitWidth: 640
        implicitHeight: 260                                   // headroom for the elastic overshoot and the icons rising on hover
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region { item: hitbox }                         // everything outside the dock stays click-through

        WlrLayershell.namespace: "mybar-dock"
        WlrLayershell.layer: WlrLayer.Overlay

        HyprlandFocusGrab {                                   // keybind mode only: click anywhere else to put the dock away
            windows: [win]
            active: DockState.open && DockState.pinned          // not while it was opened by hover, or it would steal your clicks
            onCleared: DockState.hide()
        }

        Timer { id: hideTimer; interval: 800; onTriggered: DockState.hide() }   // after launching, let the bounce play, then hide

        function run(cmd) { Quickshell.execDetached(cmd); hideTimer.restart() }

        Item { id: hitbox; x: pill.x; y: pill.y - 40; width: pill.width; height: pill.height + 40 }

        Rectangle {
            id: pill
            anchors.horizontalCenter: parent.horizontalCenter
            width: row.implicitWidth + 44
            height: 84                                        // the bar is 36 tall
            radius: 28
            color: Theme.bg
            border.width: 1
            border.color: Theme.border

            // rises from below the screen with an elastic overshoot, and drops back with a wind-up
            y: DockState.open ? win.height - height - win.gap : win.height + 12
            Behavior on y {
                NumberAnimation {
                    duration: DockState.open ? 1100 : 650
                    easing.type: DockState.open ? Easing.OutElastic : Easing.InBack
                    easing.period: 0.5
                    easing.overshoot: 3
                }
            }

            // a light sweep that glides across the glass every few seconds
            ClippingRectangle {
                anchors.fill: parent
                radius: pill.radius
                color: "transparent"

                Rectangle {
                    id: shine
                    property real sweep: 0
                    width: 90
                    height: parent.height * 2
                    y: -parent.height / 2
                    x: -140 + sweep * (parent.width + 280)
                    rotation: 18
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "#00ffffff" }
                        GradientStop { position: 0.5; color: "#26ffffff" }
                        GradientStop { position: 1; color: "#00ffffff" }
                    }
                    SequentialAnimation on sweep {
                        running: DockState.open && win.visible
                        loops: Animation.Infinite
                        PauseAnimation { duration: 1200 }
                        NumberAnimation { from: 0; to: 1; duration: 1500; easing.type: Easing.InOutSine }
                        PauseAnimation { duration: 3500 }
                    }
                }
            }

            Row {
                id: row
                anchors.centerIn: parent
                spacing: 16

                DockItem {
                    slot: 0; kind: "grid"; label: "More apps"
                    colorA: "#6B78F0"; colorB: "#3A44A8"
                    pointerX: tracker.mouseX - row.x; pointerIn: tracker.containsMouse
                    onActivated: win.run(["qs", "-c", "launcher", "ipc", "call", "launcher", "toggle"])
                }

                Item {                                        // divider
                    width: 1
                    height: 56
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 38; color: Theme.border }
                }

                DockItem {
                    slot: 1; kind: "code"; label: "VS Code"
                    colorA: "#2B8CEB"; colorB: "#0A4C9E"
                    pointerX: tracker.mouseX - row.x; pointerIn: tracker.containsMouse
                    onActivated: win.run(["code"])
                }
                DockItem {
                    slot: 2; kind: "terminal"; label: "Terminal"
                    colorA: "#34344A"; colorB: "#0F0F18"
                    pointerX: tracker.mouseX - row.x; pointerIn: tracker.containsMouse
                    onActivated: win.run(["sh", Quickshell.shellPath("term.sh")])
                }
                DockItem {
                    slot: 3; kind: "files"; label: "Files"
                    colorA: "#4F9CFF"; colorB: "#1E5FD0"
                    pointerX: tracker.mouseX - row.x; pointerIn: tracker.containsMouse
                    onActivated: win.run(["dolphin"])
                }
                DockItem {
                    slot: 4; kind: "globe"; label: "Brave"
                    colorA: "#FF7139"; colorB: "#E2400F"
                    pointerX: tracker.mouseX - row.x; pointerIn: tracker.containsMouse
                    onActivated: win.run(["brave-browser"])
                }
                DockItem {
                    slot: 5; kind: "nvim"; label: "Neovim"
                    colorA: "#1F3D2B"; colorB: "#0B1A12"
                    pointerX: tracker.mouseX - row.x; pointerIn: tracker.containsMouse
                    onActivated: win.run(["sh", Quickshell.shellPath("term.sh"), "nvim"])
                }
            }

            // tracks the cursor for the magnify effect; clicks pass straight through to the icons
            MouseArea {
                id: tracker
                anchors { fill: parent; topMargin: -40 }        // also covers the space the icons rise into
                z: 100
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                onContainsMouseChanged: DockState.hoverDock = containsMouse
            }
        }
    }
}
