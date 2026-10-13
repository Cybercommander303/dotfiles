import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root

    // ---- helpers ---------------------------------------------------------
    function clamp01(v) { return Math.max(0, Math.min(1, v)); }
    function sstep(a, b, x) { var t = clamp01((x - a) / (b - a)); return t * t * (3 - 2 * t); }
    function easeOutCubic(t) { return 1 - Math.pow(1 - t, 3); }
    function easeOutBack(t) { var c1 = 1.5, c3 = c1 + 1; return 1 + c3 * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2); }

    // ---- open / close: "screen turn-on" ----------------------------------
    // opens as a thin line that stretches sideways, then unfolds upward/downward.
    // closing plays the same thing backwards.
    property bool open: false
    property real progress: open ? 1 : 0
    Behavior on progress {
        NumberAnimation { duration: root.open ? 760 : 460; easing.type: Easing.Linear }
    }
    readonly property real sx: easeOutCubic(clamp01(progress / 0.42))
    readonly property real sy: 0.012 + 0.988 * easeOutBack(clamp01((progress - 0.30) / 0.70))
    readonly property real contentOp: clamp01((progress - 0.62) / 0.30)

    // ---- size (adapts to the screen) -------------------------------------
    readonly property real scrW: screen ? screen.width : 1600
    readonly property real scrH: screen ? screen.height : 900
    readonly property int cardW: Math.round(Math.min(980, scrW * 0.68))
    readonly property int cardH: Math.round(Math.min(680, scrH * 0.70))
    readonly property int pad: 56
    readonly property int top: 92
    readonly property int sideW: 176
    readonly property int pagesX: 24 + sideW + 24
    readonly property real contentW: cardW - pagesX - 24
    readonly property int pageW: Math.round(Math.max(386, contentW * 0.58))
    readonly property int previewX: pagesX + pageW + 20
    readonly property int previewW: cardW - 24 - previewX
    readonly property int previewH: cardH - top - 112

    // ---- sections --------------------------------------------------------
    property int current: 0     // highlighted in the sidebar (changes instantly)
    property int shown: 0       // page actually on screen (changes after the old page has left)
    property bool goingDown: true
    function setCurrent(i) {
        if (i === current) return;
        goingDown = i > current;
        current = i;
        switchTimer.restart();
    }
    Timer { id: switchTimer; interval: 130; onTriggered: root.shown = root.current }

    // ---- tilt (real perspective via a 4x4 matrix) ------------------------
    property real nx: 0       // cursor inside card, -1..1
    property real ny: 0
    readonly property real corner: sstep(0.2, 0.95, Math.abs(nx)) * sstep(0.2, 0.95, Math.abs(ny))
    readonly property real tiltMax: 18
    readonly property real gain: (0.18 + 0.82 * corner) * clamp01((progress - 0.85) / 0.15)
    property real tiltX: -ny * tiltMax * gain     // flip these two signs if the lean looks inverted
    property real tiltY: nx * tiltMax * gain
    Behavior on tiltX { SpringAnimation { spring: 2.6; damping: 0.22; epsilon: 0.01 } }
    Behavior on tiltY { SpringAnimation { spring: 2.6; damping: 0.22; epsilon: 0.01 } }

    function ce(cxs, cys) {   // cursor proximity to one corner, 0..1
        return sstep(0.1, 0.9, cxs * nx) * sstep(0.1, 0.9, cys * ny);
    }

    readonly property var cardMatrix: {
        var cx = cardW / 2, cy = cardH / 2;
        var m = Qt.matrix4x4();
        m = m.translate(Qt.vector3d(cx, cy, 0));
        m = m.times(Qt.matrix4x4(1, 0, 0, 0,
                                 0, 1, 0, 0,
                                 0, 0, 1, 0,
                                 0, 0, -1 / 800, 1));          // perspective
        m = m.rotate(tiltX, Qt.vector3d(1, 0, 0));
        m = m.rotate(tiltY, Qt.vector3d(0, 1, 0));
        m = m.scale(sx, sy, 1);
        m = m.translate(Qt.vector3d(-cx, -cy, 0));
        return m;
    }

    function openWindow() {
        var m = Hyprland.focusedMonitor;
        if (m) {
            for (var i = 0; i < Quickshell.screens.length; i++)
                if (Quickshell.screens[i].name === m.name) root.screen = Quickshell.screens[i];
        }
        HyprSettings.load();
        open = true;
    }
    function closeWindow() { HyprSettings.revert(); open = false; nx = 0; ny = 0; }
    function toggle() { if (open) closeWindow(); else openWindow(); }

    // ---- layer-shell window ----------------------------------------------
    visible: open || progress > 0.003
    color: "transparent"
    implicitWidth: cardW + pad * 2
    implicitHeight: cardH + pad * 2
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-settings"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Item {
        id: stage
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.closeWindow()

        HoverHandler {
            onPointChanged: {
                root.nx = Math.max(-1, Math.min(1, ((point.position.x - root.pad) / root.cardW) * 2 - 1));
                root.ny = Math.max(-1, Math.min(1, ((point.position.y - root.pad) / root.cardH) * 2 - 1));
            }
            onHoveredChanged: if (!hovered) { root.nx = 0; root.ny = 0; }
        }

        Item {
            id: card
            anchors.centerIn: parent
            width: root.cardW
            height: root.cardH
            transform: Matrix4x4 { matrix: root.cardMatrix }

            // soft layered shadow
            Repeater {
                model: 5
                Rectangle {
                    required property int index
                    anchors.fill: parent
                    anchors.margins: -index * 6
                    radius: Theme.radius + index * 6
                    color: "#000000"
                    opacity: (0.12 - index * 0.022) * root.clamp01(root.progress * 2)
                }
            }

            Rectangle {
                id: face
                anchors.fill: parent
                radius: Theme.radius
                border.width: 1.5
                border.color: Theme.border
                gradient: Gradient {
                    GradientStop { position: 0; color: "#181a28" }
                    GradientStop { position: 1; color: "#0e0f17" }
                }
            }

            // bright "screen line" while the card is still collapsed
            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: Theme.accent2
                opacity: Math.max(0, 1 - root.sy * 6)
            }

            // corner ornaments (parallax: drift against the tilt)
            Item {
                id: deco
                anchors.fill: parent
                x: root.tiltY * 0.45
                y: -root.tiltX * 0.45
                opacity: root.contentOp

                CornerDeco { corner: 0; x: 12; y: 12; energy: root.ce(-1, -1) }
                CornerDeco { corner: 1; x: card.width - width - 12; y: 12; energy: root.ce(1, -1) }
                CornerDeco { corner: 2; x: card.width - width - 12; y: card.height - height - 12; energy: root.ce(1, 1) }
                CornerDeco { corner: 3; x: 12; y: card.height - height - 12; energy: root.ce(-1, 1) }
            }

            // main content (parallax: drifts slightly with the tilt)
            Item {
                id: content
                anchors.fill: parent
                x: -root.tiltY * 0.3
                y: root.tiltX * 0.3
                opacity: root.contentOp

                // title: two meshing gears + "Settings"
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 16
                    spacing: 14

                    Item {
                        width: 44
                        height: 38
                        Icon {
                            id: gearBig
                            x: 0; y: 0
                            width: 28; height: 28
                            kind: "gear"
                            color: Theme.accent
                            RotationAnimator on rotation {
                                from: 0; to: 360; duration: 9000
                                loops: Animation.Infinite
                                running: root.visible
                            }
                        }
                        Icon {
                            x: 24; y: 18
                            width: 18; height: 18
                            kind: "gear"
                            color: Theme.accent2
                            RotationAnimator on rotation {
                                from: 22; to: -338; duration: 5800
                                loops: Animation.Infinite
                                running: root.visible
                            }
                        }
                    }
                    Text {
                        height: 38
                        verticalAlignment: Text.AlignVCenter
                        text: "Settings"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fsTitle
                        font.weight: Font.Bold
                        font.letterSpacing: 1.5
                    }
                }

                // header rule with a gliding highlight
                Rectangle {
                    x: 24
                    y: 68
                    width: card.width - 48
                    height: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "transparent" }
                        GradientStop { position: 0.5; color: Theme.border }
                        GradientStop { position: 1; color: "transparent" }
                    }
                    Rectangle {
                        id: glide
                        y: -1
                        width: 140
                        height: 3
                        radius: 1.5
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: "transparent" }
                            GradientStop { position: 0.5; color: Theme.accent }
                            GradientStop { position: 1; color: "transparent" }
                        }
                        SequentialAnimation on x {
                            loops: Animation.Infinite
                            running: root.visible
                            NumberAnimation { from: 0; to: card.width - 48 - 140; duration: 3200; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 0; duration: 3200; easing.type: Easing.InOutSine }
                        }
                    }
                }

                // sidebar with an elastic selection indicator
                Item {
                    id: side
                    x: 24
                    y: root.top
                    width: root.sideW
                    height: 3 * 52

                    property real indTop: root.current * 52
                    property real indBottom: root.current * 52 + 44
                    Behavior on indTop { NumberAnimation { duration: root.goingDown ? 340 : 150; easing.type: Easing.OutCubic } }
                    Behavior on indBottom { NumberAnimation { duration: root.goingDown ? 150 : 340; easing.type: Easing.OutCubic } }

                    Rectangle {
                        width: side.width
                        y: side.indTop
                        height: side.indBottom - side.indTop
                        radius: 14
                        color: Theme.alpha(Theme.accent, 0.16)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.4)
                        Rectangle {
                            x: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 4
                            height: Math.max(12, parent.height - 20)
                            radius: 2
                            color: Theme.accent
                        }
                    }

                    Repeater {
                        model: [
                            { name: "Layout", icon: "grid" },
                            { name: "Colors", icon: "drop" },
                            { name: "Effects", icon: "spark" }
                        ]
                        delegate: Item {
                            id: tab
                            required property int index
                            required property var modelData
                            readonly property bool sel: root.current === index
                            readonly property bool hov: tabMa.containsMouse
                            y: index * 52
                            width: side.width
                            height: 44

                            Rectangle {
                                anchors.fill: parent
                                radius: 14
                                color: Theme.alpha(Theme.text, (tab.hov && !tab.sel) ? 0.05 : 0)
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Icon {
                                id: tabIcon
                                x: tab.sel ? 24 : (tab.hov ? 20 : 18)
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20
                                height: 20
                                kind: tab.modelData.icon
                                color: tab.sel ? Theme.accent : (tab.hov ? Theme.text : Theme.sub)
                                scale: tab.hov ? 1.2 : 1.0
                                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                                Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
                            }
                            Text {
                                x: tabIcon.x + 32
                                anchors.verticalCenter: parent.verticalCenter
                                text: tab.modelData.name
                                color: (tab.sel || tab.hov) ? Theme.text : Theme.sub
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fsHead
                                font.weight: tab.sel ? Font.DemiBold : Font.Normal
                                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            MouseArea {
                                id: tabMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setCurrent(tab.index)
                            }
                        }
                    }

                    Text {
                        y: 3 * 52 + 14
                        x: 8
                        text: "Esc  to close"
                        color: Theme.sub
                        opacity: 0.7
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fsSmall
                    }
                }

                // pages
                Item {
                    id: pages
                    x: root.pagesX
                    y: root.top
                    width: root.pageW
                    height: root.cardH - root.top - 24

                    SettingsPage {
                        title: "Layout"; subtitle: "Spacing and shape of your windows"
                        index: 0; current: root.shown
                        width: pages.width; height: pages.height
                        onCloseRequested: root.closeWindow()
                        SliderRow { label: "Gaps in"; key: "gapsIn"; from: 0; to: 40; suffix: " px" }
                        SliderRow { label: "Gaps out"; key: "gapsOut"; from: 0; to: 80; suffix: " px" }
                        SliderRow { label: "Border size"; key: "borderSize"; from: 0; to: 8; suffix: " px" }
                        SliderRow { label: "Corner rounding"; key: "rounding"; from: 0; to: 30; suffix: " px" }
                    }

                    SettingsPage {
                        title: "Colors"; subtitle: "Border colors and gradient"
                        index: 1; current: root.shown
                        width: pages.width; height: pages.height
                        onCloseRequested: root.closeWindow()
                        ColorRow { label: "Active border"; key: "activeA" }
                        ColorRow { label: "Active gradient"; key: "activeB" }
                        ColorRow { label: "Inactive border"; key: "inactive" }
                        SliderRow { label: "Gradient angle"; key: "angle"; from: 0; to: 360; step: 5; suffix: "°" }
                    }

                    SettingsPage {
                        title: "Effects"; subtitle: "Opacity, blur, shadows and animations"
                        index: 2; current: root.shown
                        width: pages.width; height: pages.height
                        onCloseRequested: root.closeWindow()
                        SliderRow { label: "Active opacity"; key: "activeOpacity"; from: 0.5; to: 1; step: 0.05; decimals: 2 }
                        SliderRow { label: "Inactive opacity"; key: "inactiveOpacity"; from: 0.5; to: 1; step: 0.05; decimals: 2 }
                        SwitchRow { label: "Blur"; key: "blurEnabled" }
                        SliderRow { label: "Blur size"; key: "blurSize"; from: 1; to: 20 }
                        SliderRow { label: "Blur passes"; key: "blurPasses"; from: 1; to: 6 }
                        SwitchRow { label: "Shadows"; key: "shadowEnabled" }
                        SwitchRow { label: "Animations"; key: "animationsEnabled" }
                    }
                }

                // live preview
                PreviewPane {
                    x: root.previewX
                    y: root.top
                    width: root.previewW
                    height: root.previewH
                }
                Text {
                    x: root.previewX + 4
                    y: root.top + root.previewH + 10
                    width: root.previewW - 8
                    wrapMode: Text.WordWrap
                    text: "Preview is scaled up for clarity. Blur isn't drawn here."
                    color: Theme.sub
                    opacity: 0.8
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fsSmall
                }
            }
        }
    }
}
