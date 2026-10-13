pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property bool open: false

    // qs -c wallpaper ipc call wallpaper toggle   (also: show, hide)
    IpcHandler {
        target: "wallpaper"
        function toggle(): void { root.open = !root.open }
        function show(): void { root.open = true }
        function hide(): void { root.open = false }
    }
}
