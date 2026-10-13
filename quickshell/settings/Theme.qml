pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property string fontFamily: "Montserrat"
    readonly property int fs: 13
    readonly property int fsSmall: 11
    readonly property int fsHead: 15
    readonly property int fsTitle: 19
    readonly property int labelW: 128
    readonly property int radius: 26

    readonly property color bg: "#12131c"
    readonly property color panel: "#191b29"
    readonly property color panel2: "#242738"
    readonly property color border: "#32364d"
    readonly property color text: "#eceff8"
    readonly property color sub: "#8d93b3"
    readonly property color accent: "#7c8cff"
    readonly property color accent2: "#4de1d0"
    readonly property color ok: "#7cf0a6"
    readonly property color danger: "#ff6b8b"

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
}
