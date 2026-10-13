pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property int bars: 12            // must match "bars" in cava.conf
    property var values: new Array(bars).fill(0)

    Process {
        running: true
        command: ["cava", "-p", Quickshell.shellPath("cava.conf")]
        stdout: SplitParser {
            // each line looks like "12;40;7;..." (one frame)
            onRead: data => {
                const v = data.split(";").filter(s => s.length > 0).map(Number)
                if (v.length === root.bars) root.values = v
            }
        }
    }
}
