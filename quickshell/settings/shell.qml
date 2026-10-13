import Quickshell
import Quickshell.Io

ShellRoot {
    SettingsWindow { id: win }

    // qs -c settings ipc call settings toggle
    IpcHandler {
        target: "settings"
        function toggle(): void { win.toggle() }
        function open(): void { win.openWindow() }
        function close(): void { win.closeWindow() }
    }
}
