pragma Singleton
import Quickshell
import QtQuick

// One place for every color, size and font. Change a value here and the whole bar follows.
Singleton {
    readonly property color bg:      "#e61e1e2e"   // #AARRGGBB: slightly translucent
    readonly property color surface: "#313244"
    readonly property color border:  "#45475a"
    readonly property color text:    "#cdd6f4"
    readonly property color muted:   "#6c7086"
    readonly property color accent:  "#89b4fa"
    readonly property color green:   "#a6e3a1"
    readonly property color red:     "#f38ba8"
    readonly property color cava:    "#86A2E3"
    readonly property color globe:   "#8FE882"
    readonly property color wave:    "#5F6DE3"
    readonly property string numFont: "Montserrat"
    readonly property color bulb:     "#F0E043"
    readonly property color moon:     "#8C5ECC"
    readonly property color shutdown: "#E35F5F"
    readonly property color restart:  "#E3E15F"
    readonly property color lock:     "#5FC4E3"
    readonly property color sleep:    "#5FE37E"
    readonly property color darkText: "#11111b"

    readonly property int barHeight: 36
    readonly property int radius: 12
    readonly property int fontSize: 13
    readonly property string font: "sans-serif"   // swap for e.g. "Inter" or a Nerd Font
    readonly property string iconFont: "Symbols Nerd Font"   // any installed Nerd Font name works
}
