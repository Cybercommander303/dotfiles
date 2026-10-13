import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        readonly property real panelW: 400
        readonly property bool here: !Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === modelData.name
        visible: here && (Notifs.panelOpen || panel.x < win.width)

        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "mybar-notifs"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: Notifs.panelOpen && here ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Connections {
            target: Notifs
            function onPanelOpenChanged() { if (Notifs.panelOpen) focusTimer.restart() }
        }
        Timer { id: focusTimer; interval: 60; onTriggered: keys.forceActiveFocus() }
        Item { id: keys; anchors.fill: parent; focus: true; Keys.onEscapePressed: Notifs.panelOpen = false }

        // click anywhere outside the panel to close it
        MouseArea { anchors.fill: parent; onClicked: Notifs.panelOpen = false }

        // The panel is wider than the visible part: its right edge (and right-hand corners) hang off the screen,
        // so only the left corners are rounded, and the elastic overshoot never exposes a gap.
        Rectangle {
            id: panel
            width: win.panelW + 90
            height: parent.height
            x: Notifs.panelOpen ? win.width - win.panelW : win.width + 10
            radius: 28
            color: Theme.bg
            border.width: 1
            border.color: Theme.border

            // open: springs out of the right edge with an elastic overshoot. close: pulls back slightly, then snaps away.
            Behavior on x {
                NumberAnimation {
                    duration: Notifs.panelOpen ? 1000 : 480
                    easing.type: Notifs.panelOpen ? Easing.OutElastic : Easing.InBack
                    easing.period: 0.55
                    easing.overshoot: 1.1
                }
            }

            MouseArea { anchors.fill: parent }          // swallow clicks inside the panel

            Item {
                id: body
                width: win.panelW
                height: parent.height

                // ---------- ringing bell ----------
                Bell {
                    id: bell
                    anchors { top: parent.top; topMargin: 26; horizontalCenter: parent.horizontalCenter }
                    ringing: Notifs.panelOpen
                    muted: Notifs.dnd
                }

                // ---------- profile ----------
                RowLayout {
                    id: profile
                    anchors { top: bell.bottom; topMargin: 12; left: parent.left; right: parent.right; leftMargin: 28; rightMargin: 28 }
                    spacing: 16

                    ClippingRectangle {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 64
                        radius: 32
                        color: Theme.surface
                        border.width: 2
                        border.color: pfpHit.containsMouse ? Theme.globe : Theme.accent
                        scale: pfpHit.containsMouse ? 1.07 : 1
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                        Text {
                            anchors.centerIn: parent
                            visible: img.status !== Image.Ready
                            text: "\uf007"
                            color: Theme.muted
                            font { family: Theme.iconFont; pixelSize: 26 }
                        }
                        Image {
                            id: img
                            anchors.fill: parent
                            source: SysInfo.pfp
                            sourceSize.width: 160
                            sourceSize.height: 160
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        MouseArea { id: pfpHit; anchors.fill: parent; hoverEnabled: true }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            text: SysInfo.fullName !== "" ? SysInfo.fullName : SysInfo.userName
                            elide: Text.ElideRight
                            color: Theme.text
                            font { family: "Montserrat"; pixelSize: 18; weight: Font.DemiBold }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: SysInfo.userName + "@" + SysInfo.hostName
                            elide: Text.ElideRight
                            color: Theme.muted
                            font { family: "Montserrat"; pixelSize: 11 }
                        }
                    }
                }

                // ---------- distro + window manager ----------
                RowLayout {
                    id: chips
                    anchors { top: profile.bottom; topMargin: 16; left: parent.left; right: parent.right; leftMargin: 28; rightMargin: 28 }
                    spacing: 10
                    InfoChip { Layout.fillWidth: true; icon: SysInfo.distroIcon; label: SysInfo.distroName; accent: Theme.accent }
                    InfoChip { icon: "\uf2d0"; label: SysInfo.wm; accent: Theme.globe }
                }

                // ---------- notifications ----------
                Item {
                    id: nHeader
                    anchors { top: chips.bottom; topMargin: 20; left: parent.left; right: parent.right; leftMargin: 28; rightMargin: 28 }
                    height: 28

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Notifications"
                        color: Theme.text
                        font { family: "Montserrat"; pixelSize: 14; weight: Font.DemiBold }
                    }
                    Rectangle {
                        id: clearBtn
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        width: clearTxt.implicitWidth + 22
                        height: 24
                        radius: 8
                        color: clearHit.containsMouse ? Theme.red : "transparent"
                        border.width: 1
                        border.color: Theme.red
                        opacity: Notifs.history.length > 0 ? 1 : 0
                        scale: clearHit.containsMouse ? 1.06 : 1
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        Behavior on color   { ColorAnimation { duration: 180 } }
                        Behavior on scale   { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        Text {
                            id: clearTxt
                            anchors.centerIn: parent
                            text: "Clear all"
                            color: clearHit.containsMouse ? Theme.darkText : Theme.red
                            font { family: "Montserrat"; pixelSize: 10; weight: Font.DemiBold }
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }
                        MouseArea {
                            id: clearHit
                            anchors.fill: parent
                            enabled: Notifs.history.length > 0
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifs.clearAll()
                        }
                    }
                }

                ListView {
                    id: nList
                    anchors { top: nHeader.bottom; topMargin: 10; left: parent.left; right: parent.right; bottom: controls.top; leftMargin: 20; rightMargin: 20; bottomMargin: 18 }
                    clip: true
                    spacing: 10
                    boundsBehavior: Flickable.StopAtBounds
                    model: ScriptModel { values: Notifs.history }

                    add: Transition {
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 260 }
                            NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: 320; easing.type: Easing.OutBack }
                        }
                    }
                    remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 180 } }
                    displaced: Transition { NumberAnimation { properties: "y"; duration: 280; easing.type: Easing.OutCubic } }

                    delegate: Item {
                        id: nrow
                        required property var modelData
                        width: ListView.view.width
                        height: ncard.height

                        NotifCard {
                            id: ncard
                            notif: nrow.modelData
                            width: parent.width
                            hovered: nHit.containsMouse
                        }

                        // click = slingshot to the right, then dismiss
                        SequentialAnimation {
                            id: sling
                            NumberAnimation { target: ncard; property: "slide"; to: -26; duration: 150; easing.type: Easing.OutQuad }
                            ParallelAnimation {
                                NumberAnimation { target: ncard; property: "slide"; to: 520; duration: 320; easing.type: Easing.InCubic }
                                NumberAnimation { target: ncard; property: "opacity"; to: 0; duration: 320 }
                            }
                            ScriptAction { script: nrow.modelData.dismiss() }
                        }
                        MouseArea {
                            id: nHit
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sling.restart()
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 10
                        visible: nList.count === 0
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "\uf0f3"
                            color: Theme.surface
                            font { family: Theme.iconFont; pixelSize: 40 }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No notifications"
                            color: Theme.muted
                            font { family: "Montserrat"; pixelSize: 12 }
                        }
                    }
                }

                // ---------- sliders + quick toggles ----------
                ColumnLayout {
                    id: controls
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 28; rightMargin: 28; bottomMargin: 28 }
                    spacing: 22

                    SliderRow {
                        id: sound
                        Layout.fillWidth: true
                        readonly property var sink: Pipewire.defaultAudioSink
                        readonly property var audio: sink ? sink.audio : null
                        PwObjectTracker { objects: [sound.sink] }

                        accent: Theme.wave
                        value: audio ? audio.volume : 0
                        icon: !audio || audio.muted || audio.volume === 0 ? "\uf026" : (audio.volume < 0.5 ? "\uf027" : "\uf028")
                        onMoved: v => { if (audio) { audio.volume = v; if (v > 0) audio.muted = false } }
                        onIconClicked: if (audio) audio.muted = !audio.muted
                    }

                    SliderRow {
                        Layout.fillWidth: true
                        accent: Theme.bulb
                        spin: true
                        enabled: Brightness.available          // greyed out if no backlight / DDC monitor found
                        value: Brightness.value
                        icon: "\uf185"
                        onMoved: v => Brightness.set(v)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        ToggleButton { icon: "\uf072"; label: "Airplane"; accent: Theme.lock; kind: 0; active: Quick.airplane; onClicked: Quick.toggleAirplane() }
                        ToggleButton { icon: Notifs.dnd ? "\uf1f6" : "\uf0f3"; label: "DND"; accent: Theme.wave; kind: 1; active: Notifs.dnd; onClicked: Notifs.dnd = !Notifs.dnd }
                        ToggleButton { icon: "\uf186"; label: "Night light"; accent: "#F5A623"; kind: 2; active: Quick.night; onClicked: Quick.toggleNight() }
                    }
                }
            }
        }
    }
}
