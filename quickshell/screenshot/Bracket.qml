import QtQuick

// One independent corner bracket, sitting exactly on a corner of the real selection.
// corner: 0 TL, 1 TR, 2 BR, 3 BL. The item's origin (0,0) IS the selection corner.
Item {
    id: b
    property int corner: 0
    property real armLen: 22
    property real boost: 0          // 0..1 flash on confirm
    readonly property int dx: (corner === 0 || corner === 3) ? 1 : -1
    readonly property int dy: (corner === 0 || corner === 1) ? 1 : -1

    width: 0
    height: 0
    scale: 1 + 0.4 * boost

    // glow
    Rectangle { x: b.dx > 0 ? -2 : -b.armLen + 2; y: -3.5; width: b.armLen; height: 7; radius: 3.5; color: Config.alpha(Config.cyan, 0.14 + 0.25 * b.boost) }
    Rectangle { x: -3.5; y: b.dy > 0 ? -2 : -b.armLen + 2; width: 7; height: b.armLen; radius: 3.5; color: Config.alpha(Config.cyan, 0.14 + 0.25 * b.boost) }
    // core
    Rectangle { x: b.dx > 0 ? -1.25 : -b.armLen + 1.25; y: -1.25; width: b.armLen; height: 2.5; radius: 1.25; color: Config.white }
    Rectangle { x: -1.25; y: b.dy > 0 ? -1.25 : -b.armLen + 1.25; width: 2.5; height: b.armLen; radius: 1.25; color: Config.white }

    // node + breathing halo (each corner breathes out of phase)
    Rectangle {
        id: halo
        x: -8; y: -8; width: 16; height: 16; radius: 8
        color: Config.alpha(Config.cyan, 0.22)
        SequentialAnimation on scale {
            loops: Animation.Infinite
            PauseAnimation { duration: b.corner * 280 }
            NumberAnimation { to: 1.5; duration: 900; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.7; duration: 900; easing.type: Easing.InOutSine }
        }
    }
    Rectangle { x: -3; y: -3; width: 6; height: 6; radius: 3; color: Config.cyan }
}
