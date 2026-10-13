pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property string distroName: "Linux"
    property string distroId: ""
    property string userName: Quickshell.env("USER")
    property string fullName: ""
    property string hostName: ""

    readonly property string wm: Quickshell.env("XDG_CURRENT_DESKTOP") || "Hyprland"
    readonly property string pfp: "file://" + Quickshell.env("HOME") + "/.face"     // put your picture at ~/.face
    // Nerd Font logos: Fedora, NixOS, generic penguin
    readonly property string distroIcon: distroId === "fedora" ? "\uf30a" : (distroId === "nixos" ? "\uf313" : "\uf17c")

    FileView { id: osr; path: "/etc/os-release"; blockLoading: true; printErrors: false }

    Process {
        running: true
        command: ["sh", "-c", "getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1; uname -n"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n")
                root.fullName = l[0] || ""
                root.hostName = l[1] || ""
            }
        }
    }

    Component.onCompleted: {
        for (const line of osr.text().split("\n")) {
            const m = line.match(/^([A-Z_]+)=(.*)$/)
            if (!m) continue
            const v = m[2].replace(/^"|"$/g, "")
            if (m[1] === "ID") distroId = v
            else if (m[1] === "PRETTY_NAME") distroName = v
        }
    }
}
