import Quickshell
import Quickshell.Io

ShellRoot {
    CaptureOverlay { id: cap }

    // qs -c screenshot ipc call capture start
    IpcHandler {
        target: "capture"
        function start(): void { cap.start() }
        function cancel(): void { cap.cancel() }
        function toggle(): void { if (cap.mode === "select") cap.cancel(); else cap.start() }
    }
}
