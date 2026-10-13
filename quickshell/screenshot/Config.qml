pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // ---- palette --------------------------------------------------------
    readonly property color smoke: "#080B12"
    readonly property color cyan: "#67E8F9"
    readonly property color blue: "#3B82F6"
    readonly property color white: "#F8FAFC"
    readonly property color charcoal: "#111827"
    readonly property color sub: "#8FA3BF"
    readonly property color ok: "#7CF0C0"
    readonly property string mono: "JetBrains Mono"

    // ---- behaviour ------------------------------------------------------
    readonly property bool confirmOnRelease: true   // false: release keeps the box, Enter confirms
    readonly property real dimOpacity: 0.55
    readonly property int minSize: 8                // smaller drags are ignored
    readonly property int bottomClearance: 130      // px kept free at the bottom for your dock
    readonly property int cardDismissMs: 9000

    readonly property string saveDir: Quickshell.env("HOME") + "/Pictures/Screenshots"

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
}
