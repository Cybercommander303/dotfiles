pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property bool open: false

    // qs -c mybar ipc call launcher toggle   (also: show, hide)
    IpcHandler {
        target: "launcher"
        function toggle(): void { root.open = !root.open }
        function show(): void { root.open = true }
        function hide(): void { root.open = false }
    }
}
