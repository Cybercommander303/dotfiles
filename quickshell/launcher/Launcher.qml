import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        readonly property string ui: "Montserrat"
        readonly property bool here: !Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === modelData.name
        visible: here && (LauncherState.open || card.opacity > 0.01)

        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "mybar-launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: LauncherState.open && here ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        function score(e, q) {
            const name = (e.name || "").toLowerCase()
            if (name === q) return 100
            if (name.startsWith(q)) return 80
            if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 60
            if (name.includes(q)) return 40
            const rest = ((e.genericName || "") + " " + (e.comment || "") + " " + Array.from(e.keywords || []).join(" ")).toLowerCase()
            return rest.includes(q) ? 20 : 0
        }

        readonly property var results: {
            const q = search.text.trim().toLowerCase()
            const apps = DesktopEntries.applications.values.filter(e => !e.noDisplay)
            if (q === "") return apps.sort((a, b) => a.name.localeCompare(b.name))
            return apps
                .map(e => ({ e: e, s: score(e, q) }))
                .filter(x => x.s > 0)
                .sort((a, b) => (b.s - a.s) || a.e.name.localeCompare(b.e.name))
                .map(x => x.e)
        }

        function launch() {
            const entry = results[list.currentIndex]
            if (!entry) return
            entry.execute()
            LauncherState.open = false
        }

        Connections {
            target: LauncherState
            function onOpenChanged() {
                if (LauncherState.open) {
                    search.text = ""
                    list.currentIndex = 0
                    focusTimer.restart()
                }
            }
        }
        Timer { id: focusTimer; interval: 60; onTriggered: search.forceActiveFocus() }

        // invisible click-catcher: no dimming, clicking outside the card closes it
        MouseArea { anchors.fill: parent; onClicked: LauncherState.open = false }

        TiltCard {
            id: card
            shown: LauncherState.open
            width: 580
            height: 350

            Rectangle {
                id: searchBox
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 16 }
                height: 46
                radius: 13
                color: Theme.surface
                border.width: 1
                border.color: search.activeFocus ? Theme.accent : Theme.border
                Behavior on border.color { ColorAnimation { duration: 200 } }

                RowLayout {
                    anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                    spacing: 12

                    Text {
                        text: "\uf002"
                        color: search.activeFocus ? Theme.accent : Theme.muted
                        font { family: Theme.iconFont; pixelSize: 16 }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        color: Theme.text
                        selectByMouse: true
                        clip: true
                        font { family: win.ui; pixelSize: 15 }
                        onTextChanged: list.currentIndex = 0

                        Text {
                            visible: search.text.length === 0
                            text: "Search apps…"
                            color: Theme.muted
                            font: search.font
                        }

                        Keys.onPressed: event => {
                            const ctrl = event.modifiers & Qt.ControlModifier
                            const down = event.key === Qt.Key_Down || event.key === Qt.Key_Tab || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))
                            const up = event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))
                            if (down) { list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1); event.accepted = true }
                            else if (up) { list.currentIndex = Math.max(0, list.currentIndex - 1); event.accepted = true }
                            else if (event.key === Qt.Key_PageDown) { list.currentIndex = Math.min(list.count - 1, list.currentIndex + 5); event.accepted = true }
                            else if (event.key === Qt.Key_PageUp) { list.currentIndex = Math.max(0, list.currentIndex - 5); event.accepted = true }
                            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { win.launch(); event.accepted = true }
                            else if (event.key === Qt.Key_Escape) { LauncherState.open = false; event.accepted = true }
                        }
                    }
                }
            }

            ListView {
                id: list
                anchors { top: searchBox.bottom; topMargin: 10; left: parent.left; right: parent.right; bottom: footer.top; leftMargin: 16; rightMargin: 16 }
                clip: true
                model: win.results
                spacing: 4
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 140
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                highlight: Rectangle {
                    width: list.width
                    height: 48
                    radius: 11
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
                    border.color: Theme.accent
                    border.width: 1
                }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool current: ListView.isCurrentItem

                    width: ListView.view.width
                    height: 48

                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        spacing: 12

                        IconImage {
                            implicitSize: 30
                            source: Quickshell.iconPath(row.modelData.icon || "application-x-executable")
                            scale: row.current ? 1.12 : 1
                            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.name
                                elide: Text.ElideRight
                                color: row.current ? Theme.accent : Theme.text
                                font { family: win.ui; pixelSize: 13; weight: Font.DemiBold }
                                Behavior on color { ColorAnimation { duration: 160 } }
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: row.modelData.comment || row.modelData.genericName || ""
                                elide: Text.ElideRight
                                color: Theme.muted
                                font { family: win.ui; pixelSize: 10 }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: list.currentIndex = row.index
                        onClicked: { list.currentIndex = row.index; win.launch() }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    text: "No apps found"
                    color: Theme.muted
                    font { family: win.ui; pixelSize: 13 }
                }
            }

            Item {
                id: footer
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 20; rightMargin: 20 }
                height: 30

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "↑↓ navigate     ↵ launch     esc close"
                    color: Theme.muted
                    font { family: win.ui; pixelSize: 10 }
                }
                Text {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: list.count + (list.count === 1 ? " app" : " apps")
                    color: Theme.muted
                    font { family: win.ui; pixelSize: 10 }
                }
            }
        }
    }
}
