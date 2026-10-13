import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        readonly property bool here: !Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === modelData.name
        visible: here && toasts.count > 0

        anchors { top: true; bottom: true; right: true }
        implicitWidth: 400
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region { item: toasts }                    // only the pop-ups themselves take clicks

        WlrLayershell.namespace: "mybar-toasts"
        WlrLayershell.layer: WlrLayer.Overlay

        ListView {
            id: toasts
            anchors { top: parent.top; right: parent.right; topMargin: 56; rightMargin: 14 }
            width: 372
            height: contentHeight
            spacing: 10
            interactive: false
            model: ScriptModel { values: Notifs.popups }

            add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
            remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 150 } }
            displaced: Transition { NumberAnimation { properties: "y"; duration: 260; easing.type: Easing.OutCubic } }

            delegate: Item {
                id: toast
                required property var modelData
                readonly property bool hovering: hit.containsMouse
                width: ListView.view.width
                height: card.height

                // auto-hide (paused while hovering; critical ones stay until clicked)
                Timer {
                    interval: toast.modelData.expireTimeout > 0 ? toast.modelData.expireTimeout * 1000 : 6000
                    running: !toast.hovering && !sling.running && !(card.critical && toast.modelData.expireTimeout <= 0)
                    onTriggered: Notifs.hidePopup(toast.modelData)
                }

                NotifCard {
                    id: card
                    notif: toast.modelData
                    width: parent.width
                    slide: 420
                    hovered: toast.hovering
                }

                // slides in from the right with a little overshoot
                NumberAnimation {
                    id: enter
                    target: card
                    property: "slide"
                    from: 420
                    to: 0
                    duration: 560
                    easing.type: Easing.OutBack
                    easing.overshoot: 0.9
                }
                Component.onCompleted: enter.start()

                // slingshot: pull back a little, then fling off to the right
                SequentialAnimation {
                    id: sling
                    NumberAnimation { target: card; property: "slide"; to: -30; duration: 160; easing.type: Easing.OutQuad }
                    ParallelAnimation {
                        NumberAnimation { target: card; property: "slide"; to: 520; duration: 330; easing.type: Easing.InCubic }
                        NumberAnimation { target: card; property: "opacity"; to: 0; duration: 330 }
                    }
                    ScriptAction { script: Notifs.hidePopup(toast.modelData) }
                }

                MouseArea {
                    id: hit
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { enter.stop(); sling.restart() }
                }
            }
        }
    }
}
