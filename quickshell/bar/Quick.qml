pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Airplane mode and night light. The real state is re-checked every few seconds.
Singleton {
    id: root
    property bool airplane: false
    property bool night: false
    property int kelvin: 4000

    function toggleAirplane() {
        Quickshell.execDetached(["sh", "-c", airplane
            ? "nmcli radio all on; rfkill unblock bluetooth"
            : "nmcli radio all off; rfkill block bluetooth"])
        airplane = !airplane
        recheck.restart()
    }

    function toggleNight() {
        if (night) Quickshell.execDetached(["pkill", "-x", "hyprsunset"])
        else Quickshell.execDetached(["hyprsunset", "-t", String(kelvin)])
        night = !night
        recheck.restart()
    }

    function check() {
        if (!radio.running) radio.running = true
        if (!sun.running) sun.running = true
    }

    Timer { id: recheck; interval: 1200; onTriggered: root.check() }
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.check() }

    Process {
        id: radio
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: root.airplane = text.trim() === "disabled" }
    }
    Process {
        id: sun
        command: ["pidof", "hyprsunset"]
        onExited: (code, status) => root.night = (code === 0)
    }
}
