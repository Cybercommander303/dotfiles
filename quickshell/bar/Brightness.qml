pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Laptop backlight -> brightnessctl.  External monitor on a desktop -> ddcutil (DDC/CI).
Singleton {
    id: root
    property real value: 0.5
    property string backend: "none"
    readonly property bool available: backend !== "none"

    function set(v) {
        value = Math.max(0.05, Math.min(1, v))      // never fully black
        debounce.restart()
    }

    Timer {
        id: debounce
        interval: root.backend === "ddcutil" ? 350 : 60      // DDC is slow, don't spam it
        onTriggered: {
            if (setProc.running) { debounce.restart(); return }
            const pct = String(Math.round(root.value * 100))
            setProc.command = root.backend === "brightnessctl"
                ? ["brightnessctl", "set", pct + "%"]
                : ["ddcutil", "setvcp", "10", pct]
            setProc.running = true
        }
    }
    Process { id: setProc }

    Process {
        running: true
        command: ["brightnessctl", "-c", "backlight", "-m"]       // device,class,current,percent,max
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split("\n")[0].split(",")
                if (f.length >= 5 && f[1] === "backlight") {
                    root.backend = "brightnessctl"
                    root.value = parseInt(f[3]) / 100
                } else {
                    ddc.running = true
                }
            }
        }
    }
    Process {
        id: ddc
        command: ["ddcutil", "getvcp", "10", "--brief"]           // VCP 10 C current max
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(/\s+/)
                if (f[0] === "VCP" && f[2] === "C") {
                    root.backend = "ddcutil"
                    root.value = parseInt(f[3]) / parseInt(f[4])
                }
            }
        }
    }
}
