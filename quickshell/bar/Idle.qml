pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// "enabled" means hypridle is running. Toggling kills or starts the hypridle process.
Singleton {
    id: root
    property bool enabled: true

    function toggle() {
        if (enabled) Quickshell.execDetached(["pkill", "-x", "hypridle"])
        else Quickshell.execDetached(["hypridle"])
        // If you run hypridle as a systemd user service, use these instead:
        //   stop:  Quickshell.execDetached(["systemctl", "--user", "stop", "hypridle"])
        //   start: Quickshell.execDetached(["systemctl", "--user", "start", "hypridle"])
        enabled = !enabled          // optimistic; the re-check below corrects it if it didn't work
        recheck.restart()
    }

    function check() { if (!probe.running) probe.running = true }

    Timer { id: recheck; interval: 800; onTriggered: root.check() }
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.check() }

    Process {
        id: probe
        command: ["pidof", "hypridle"]
        onExited: (code, status) => root.enabled = (code === 0)
    }
}
