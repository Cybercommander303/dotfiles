pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Talks to NetworkManager through nmcli and exposes the results as properties.
Singleton {
    id: root

    property var networks: []          // [{ ssid, signal, secure, active, saved }]
    property var saved: ({})           // ssid -> true for networks with a saved profile
    property string activeSsid: ""
    property string busySsid: ""       // network currently being connected
    property string message: ""
    property bool failed: false

    property string _pendingSsid: ""
    property bool _pendingNewPassword: false

    // nmcli -t escapes ":" inside values as "\:"; split on real colons only
    function splitTerse(line) {
        const out = []
        let cur = ""
        for (let i = 0; i < line.length; i++) {
            const c = line[i]
            if (c === "\\" && i + 1 < line.length) { cur += line[i + 1]; i++ }
            else if (c === ":") { out.push(cur); cur = "" }
            else cur += c
        }
        out.push(cur)
        return out
    }

    function refresh() {
        if (savedProc.running || listProc.running) return
        savedProc.running = true               // saved profiles first, then the scan list
    }

    function connect(ssid, password) {
        if (connectProc.running) return
        busySsid = ssid
        message = ""
        failed = false
        _pendingSsid = ssid
        _pendingNewPassword = password.length > 0

        if (password.length > 0)
            connectProc.command = ["nmcli", "device", "wifi", "connect", ssid, "password", password]
        else if (saved[ssid])
            connectProc.command = ["nmcli", "connection", "up", "id", ssid]
        else
            connectProc.command = ["nmcli", "device", "wifi", "connect", ssid]
        connectProc.running = true
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: savedProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        environment: ({ "LC_ALL": "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                const s = {}
                for (const line of text.split("\n")) {
                    if (!line) continue
                    const f = root.splitTerse(line)
                    if (f[1] === "802-11-wireless") s[f[0]] = true
                }
                root.saved = s
                listProc.running = true
            }
        }
    }

    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list"]
        environment: ({ "LC_ALL": "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                const best = {}
                let active = ""
                for (const line of text.split("\n")) {
                    if (!line) continue
                    const f = root.splitTerse(line)        // [inuse, ssid, signal, security]
                    const ssid = f[1]
                    if (!ssid) continue
                    const n = {
                        ssid: ssid,
                        signal: parseInt(f[2]) || 0,
                        secure: f[3] !== "" && f[3] !== "--",
                        active: f[0] === "*",
                        saved: !!root.saved[ssid]
                    }
                    if (n.active) active = ssid
                    const prev = best[ssid]
                    if (!prev || n.active || (!prev.active && n.signal > prev.signal)) best[ssid] = n
                }
                const arr = Object.keys(best).map(k => best[k])
                arr.sort((a, b) => (b.active - a.active) || (b.signal - a.signal))
                root.networks = arr
                root.activeSsid = active
            }
        }
    }

    Process {
        id: connectProc
        environment: ({ "LC_ALL": "C" })
        stderr: StdioCollector { id: connErr }
        onExited: (code, status) => Qt.callLater(() => {
            const ssid = root._pendingSsid
            root.busySsid = ""
            if (code === 0) {
                root.failed = false
                root.message = "Connected to " + ssid
            } else {
                root.failed = true
                root.message = connErr.text.trim().split("\n")[0] || "Could not connect"
                // a failed first attempt can leave a broken saved profile behind; remove it
                if (root._pendingNewPassword) {
                    deleteProc.command = ["nmcli", "connection", "delete", "id", ssid]
                    deleteProc.running = true
                }
            }
            root.refresh()
        })
    }

    Process { id: deleteProc }
}
