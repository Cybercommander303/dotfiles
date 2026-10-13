import Quickshell
import Quickshell.Wayland
import QtQuick

// A thin transparent strip at the bottom-middle of every screen. Push the cursor into it and the dock rises.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: zone
        required property var modelData
        screen: modelData

        anchors { bottom: true }
        implicitWidth: 360
        implicitHeight: 4
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "mybar-dock-trigger"
        WlrLayershell.layer: WlrLayer.Top                    // sits under fullscreen windows, so games and video don't trigger it

        Timer {                                              // a short dwell, so brushing past the edge doesn't pop it up
            id: dwell
            interval: 140
            onTriggered: DockState.hoverOpen(zone.modelData.name)
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: dwell.restart()
            onExited: dwell.stop()
            onContainsMouseChanged: DockState.hoverZone = containsMouse
        }
    }
}
