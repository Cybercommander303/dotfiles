pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property bool open: false
    property bool pinned: false            // opened with the keybind: stays until you toggle it / click elsewhere
    property string screenName: ""         // which monitor to show on ("" = whichever has focus)
    property bool hoverZone: false         // cursor is on the invisible strip at the bottom edge
    property bool hoverDock: false         // cursor is on the dock itself
    readonly property bool hovering: hoverZone || hoverDock

    onOpenChanged: if (!open) pinned = false
    onHoveringChanged: {
        if (hovering) leave.stop()
        else if (open && !pinned) leave.restart()          // opened by hover: put it away shortly after the cursor leaves
    }

    function hoverOpen(name) { if (!open) { screenName = name; pinned = false; open = true } }
    function pin() { screenName = ""; pinned = true; open = true }
    function hide() { open = false }

    Timer {
        id: leave
        interval: 700
        onTriggered: if (!root.pinned && !root.hovering) root.open = false
    }

    // qs -c dock ipc call dock toggle   (also: show, hide)
    IpcHandler {
        target: "dock"
        function toggle(): void { if (root.open) root.hide(); else root.pin() }
        function show(): void { root.pin() }
        function hide(): void { root.hide() }
    }
}
