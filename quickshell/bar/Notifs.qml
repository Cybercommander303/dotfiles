pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root
    property bool panelOpen: false
    property bool dnd: false                  // do not disturb: no pop-ups (they still land in the panel)
    property var popups: []                   // notifications currently shown as pop-ups
    property var stamps: ({})                 // notification id -> time it arrived

    // everything the server is holding, newest first
    readonly property var history: {
        const v = server.trackedNotifications.values
        const out = []
        for (let i = v.length - 1; i >= 0; i--) out.push(v[i])
        return out
    }

    onPanelOpenChanged: if (panelOpen) popups = []      // the panel already shows everything

    // qs -c bar ipc call notifs toggle   (also: show, hide, dnd)
    IpcHandler {
        target: "notifs"
        function toggle(): void { root.panelOpen = !root.panelOpen }
        function show(): void { root.panelOpen = true }
        function hide(): void { root.panelOpen = false }
        function dnd(): void { root.dnd = !root.dnd }
    }

    NotificationServer {
        id: server
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: false
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true
            const s = root.stamps
            s[n.id] = new Date()
            root.stamps = s
            n.closed.connect(() => root.hidePopup(n))

            if (root.panelOpen) return
            if (root.dnd && n.urgency !== NotificationUrgency.Critical) return
            root.popups = [n].concat(root.popups)
        }
    }

    function hidePopup(n) { popups = popups.filter(p => p !== n) }

    function timeOf(n) {
        if (!n || !stamps[n.id]) return ""
        return Qt.formatDateTime(stamps[n.id], "hh:mm")
    }

    function clearAll() {
        const v = server.trackedNotifications.values
        const all = []
        for (let i = 0; i < v.length; i++) all.push(v[i])
        for (const n of all) n.dismiss()
    }
}
