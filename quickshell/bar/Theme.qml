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
    readonly property color green:   "#75B06F"
    readonly property color red:     "#f38ba8"
    readonly property color cava:    "#AA96DA"
    readonly property color globe:   "#6394e6"
    readonly property color wave:    "#5F6DE3"
    readonly property string numFont: "Montserrat"
    readonly property color bulb:     "#9CD5FF"
    readonly property color moon:     "#8C5ECC"
    readonly property color shutdown: "#C4E2F5"
    readonly property color restart:  "#2C5EAD"
    readonly property color lock:     "#1591DC"
    readonly property color sleep:    "#4BB8FA"
    readonly property color darkText: "#11111b"

    readonly property int barHeight: 36
    readonly property int radius: 12
    readonly property int fontSize: 12
    readonly property string font: "Montserrat"   // swap for e.g. "Inter" or a Nerd Font
    readonly property string iconFont: "JetBrainsNerd Mono Font"   // any installed Nerd Font name works
}
