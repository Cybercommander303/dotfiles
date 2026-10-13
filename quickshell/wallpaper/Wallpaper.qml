import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        readonly property string ui: "Montserrat"
        readonly property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"     // <- change to your folder
        readonly property bool here: !Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === modelData.name
        visible: here && (WallpaperState.open || card.opacity > 0.01)

        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "mybar-wallpaper"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WallpaperState.open && here ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        FolderListModel {
            id: files
            folder: "file://" + win.dir
            nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.JPG", "*.JPEG", "*.PNG", "*.WEBP"]
            showDirs: false
            sortField: FolderListModel.Name
        }

        // hyprpaper: preload -> apply to all monitors -> free the old ones. The path is passed as $1 (safe with spaces).
        // The last bit remembers your choice in ~/.local/state/mybar/wallpaper
        function apply(path) {
            if (!path) return
            Quickshell.execDetached(["sh", "-c",
                'hyprctl hyprpaper preload "$1"; hyprctl hyprpaper wallpaper ",$1"; hyprctl hyprpaper unload unused; ' +
                'mkdir -p "$HOME/.local/state/mybar" && printf "%s" "$1" > "$HOME/.local/state/mybar/wallpaper"',
                "sh", path])
            WallpaperState.open = false
        }

        Connections {
            target: WallpaperState
            function onOpenChanged() {
                if (WallpaperState.open) {
                    grid.currentIndex = 0
                    focusTimer.restart()
                }
            }
        }
        Timer { id: focusTimer; interval: 60; onTriggered: grid.forceActiveFocus() }

        MouseArea { anchors.fill: parent; onClicked: WallpaperState.open = false }

        TiltCard {
            id: card
            shown: WallpaperState.open
            width: 700
            height: 400

            Item {
                id: header
                anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: 22; rightMargin: 22; topMargin: 8 }
                height: 40

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Wallpapers"
                    color: Theme.text
                    font { family: win.ui; pixelSize: 15; weight: Font.DemiBold }
                }
                Text {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: files.count + (files.count === 1 ? " image" : " images")
                    color: Theme.muted
                    font { family: win.ui; pixelSize: 11 }
                }
            }

            GridView {
                id: grid
                anchors { top: header.bottom; left: parent.left; right: parent.right; bottom: footer.top; leftMargin: 16; rightMargin: 16; bottomMargin: 4 }
                clip: true
                model: files
                cellWidth: Math.floor(width / 3)
                cellHeight: Math.floor(cellWidth * 0.62)
                keyNavigationEnabled: true
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 160

                Keys.onReturnPressed: win.apply(files.get(currentIndex, "filePath"))
                Keys.onEnterPressed: win.apply(files.get(currentIndex, "filePath"))
                Keys.onEscapePressed: WallpaperState.open = false

                // selection frame that slides between thumbnails
                highlight: Rectangle {
                    width: grid.cellWidth
                    height: grid.cellHeight
                    radius: 14
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                    border.color: Theme.accent
                    border.width: 1
                }

                delegate: Item {
                    id: cell
                    required property int index
                    required property url fileUrl
                    required property string filePath
                    required property string fileBaseName
                    readonly property bool active: GridView.isCurrentItem || area.containsMouse

                    width: grid.cellWidth
                    height: grid.cellHeight

                    ClippingRectangle {
                        anchors { fill: parent; margins: 7 }
                        radius: 10
                        color: Theme.surface
                        scale: cell.active ? 1.06 : 1
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

                        Image {
                            anchors.fill: parent
                            source: cell.fileUrl
                            sourceSize.width: 420
                            sourceSize.height: 260
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 250 } }
                        }

                        // file name slides up on hover / selection
                        Rectangle {
                            anchors { left: parent.left; right: parent.right }
                            height: 26
                            y: cell.active ? parent.height - height : parent.height
                            color: "#b3000000"
                            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                            Text {
                                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                verticalAlignment: Text.AlignVCenter
                                text: cell.fileBaseName
                                elide: Text.ElideRight
                                color: "white"
                                font { family: win.ui; pixelSize: 10 }
                            }
                        }
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: grid.currentIndex = cell.index
                        onClicked: { grid.currentIndex = cell.index; win.apply(cell.filePath) }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: files.count === 0
                    width: parent.width - 40
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: "No images found in\n" + win.dir
                    color: Theme.muted
                    font { family: win.ui; pixelSize: 12 }
                }
            }

            Item {
                id: footer
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 22; rightMargin: 22 }
                height: 30

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "←↑↓→ browse     ↵ apply     esc close"
                    color: Theme.muted
                    font { family: win.ui; pixelSize: 10 }
                }
            }
        }
    }
}
