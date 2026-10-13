import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root

    // idle | select | capturing | confirm | result | cancel
    property string mode: "idle"
    property real fade: 0

    // ---- real selection geometry (logical px, relative to this screen) ---
    property bool hasSel: false
    property bool dragging: false
    property int selX: 0
    property int selY: 0
    property int selW: 0
    property int selH: 0
    property real pressX: 0
    property real pressY: 0
    property real curX: 0
    property real curY: 0
    property real lastT: 0
    property real pvx: 0       // smoothed pointer velocity, px/s
    property real pvy: 0

    // ---- capture + effect state -----------------------------------------
    property string outFile: ""
    property string geom: ""
    property real tension: 0
    property real pulseT: -1
    property real ringT: 0
    property real flightT: 0
    property real exitT: 0
    property real infoT: 0
    property real ttlFrac: 1
    property bool copied: false
    property bool pendingFlight: false
    property bool simOn: false
    property int calm: 0

    readonly property string dir: {
        var d = Qt.resolvedUrl(".").toString().replace("file://", "");
        return d.endsWith("/") ? d : d + "/";
    }
    readonly property real ox: (screen && screen.x !== undefined) ? screen.x : 0
    readonly property real oy: (screen && screen.y !== undefined) ? screen.y : 0

    // ---- result card geometry --------------------------------------------
    readonly property int slotW: 200
    readonly property real slotH: Math.max(56, Math.min(140, slotW * (selH / Math.max(1, selW))))
    readonly property real contentH: Math.max(slotH, 124)
    readonly property real cardW: 512
    readonly property real cardH: contentH + 40
    readonly property real cardX: (stage.width - cardW) / 2
    readonly property real cardY: stage.height - Config.bottomClearance - cardH
    readonly property real slotX: cardX + 16
    readonly property real slotY: cardY + 16 + (contentH - slotH) / 2
    readonly property real cardT: mode === "result" ? clamp01((flightT - 0.5) / 0.5) : 0

    readonly property var ropeList: [r0, r1, r2, r3]

    // ---- helpers ---------------------------------------------------------
    function clamp01(v) { return Math.max(0, Math.min(1, v)); }
    function lerp(a, b, t) { return a + (b - a) * t; }
    function easeOutBack(t) { var c1 = 1.6, c3 = c1 + 1; return 1 + c3 * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2); }
    function wake() { calm = 0; simOn = true; }

    // ---- window ----------------------------------------------------------
    visible: mode !== "idle"
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nyx-capture"
    WlrLayershell.keyboardFocus: mode === "select" ? WlrKeyboardFocus.Exclusive
                               : (mode === "result" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None)
    mask: Region {
        item: root.mode === "select" ? stage
            : ((root.mode === "result" && root.cardT > 0.05) ? cardMask : nothing)
    }
    Item { id: nothing; width: 0; height: 0 }

    // ======================================================================
    //  control
    // ======================================================================
    function start() {
        if (mode !== "idle") return;
        var m = Hyprland.focusedMonitor;
        if (m) {
            for (var i = 0; i < Quickshell.screens.length; i++)
                if (Quickshell.screens[i].name === m.name) root.screen = Quickshell.screens[i];
        }
        resetAll();
        mode = "select";
        fade = 1;
        wake();
    }

    function cancel() {
        if (mode !== "select") return;
        dragging = false;
        mode = "cancel";
        fade = 0;
        cancelTimer.restart();
    }

    function resetAll() {
        fade = 0; tension = 0; pulseT = -1; ringT = 0; flightT = 0; exitT = 0; infoT = 0;
        ttlFrac = 1; copied = false; pendingFlight = false; outFile = "";
        dragging = false; hasSel = false; selX = 0; selY = 0; selW = 0; selH = 0;
        pvx = 0; pvy = 0; simOn = false; calm = 0;
    }

    function updateSel(x, y) {
        var cx = Math.max(0, Math.min(stage.width, x)), cy = Math.max(0, Math.min(stage.height, y));
        selX = Math.round(Math.min(pressX, cx));
        selY = Math.round(Math.min(pressY, cy));
        selW = Math.round(Math.abs(cx - pressX));
        selH = Math.round(Math.abs(cy - pressY));
        hasSel = selW >= 2 || selH >= 2;
    }

    function trackPointer(x, y) {
        var now = Date.now();
        var dt = Math.max(1, now - lastT) / 1000;
        if (lastT > 0) {
            pvx = pvx * 0.6 + ((x - curX) / dt) * 0.4;
            pvy = pvy * 0.6 + ((y - curY) / dt) * 0.4;
        }
        lastT = now;
        curX = x; curY = y;
        wake();
    }

    function requestCapture() {
        if (mode !== "select" || !hasSel || selW < Config.minSize || selH < Config.minSize) return;
        dragging = false;
        // the overlay must be invisible in the real capture: keep the surface mapped
        // (no layer open/close animation) but draw nothing, then let hyprshot grab the screen
        mode = "capturing";
        var stamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd-HHmmss");
        outFile = Config.saveDir + "/" + stamp + "_hyprshot.png";
        geom = Math.round(ox + selX) + "," + Math.round(oy + selY) + " " + selW + "x" + selH;
        captureDelay.restart();
    }

    function captureDone(code) {
        if (code !== 0) {
            console.warn("[nyx-capture] capture failed (exit " + code + "): " + capErr.text);
            errNotify.command = ["notify-send", "-u", "critical", "NYX // PHANTOM CAPTURE failed",
                                 (capErr.text !== "" ? capErr.text : "exit code " + code) + "\n(log: ~/.cache/nyx-capture/last.log)"];
            errNotify.running = true;
            mode = "idle";
            resetAll();
            return;
        }
        fade = 0;
        mode = "confirm";
        fade = 1;
        tension = 0; pulseT = -1; ringT = 0;
        wake();
        confirmAnim.restart();
    }

    function tryFlight() {
        if (img.status !== Image.Loading) startFlight();
        else { pendingFlight = true; flightFallback.restart(); }
    }
    function startFlight() {
        pendingFlight = false;
        flightFallback.stop();
        mode = "result";
        flightAnim.restart();
    }

    function dismiss() {
        if (mode !== "result") return;
        ttlAnim.stop();
        exitAnim.restart();
    }
    function finish() {
        mode = "idle";
        resetAll();
    }

    function runAction(kind) {
        actProc.command = ["bash", dir + "actions.sh", kind, outFile];
        actProc.running = false;
        actProc.running = true;
    }
    function doCopy() {
        runAction("copy");
        copied = true;
        copiedTimer.restart();
        ttlAnim.restart();
    }
    function doOpen() { runAction("open"); dismiss(); }
    function doReveal() { runAction("reveal"); dismiss(); }

    // ---- timers / processes / sim ----------------------------------------
    Timer { id: cancelTimer; interval: 240; onTriggered: root.finish() }
    Timer { id: captureDelay; interval: 130; onTriggered: capProc.running = true }
    Timer { id: copiedTimer; interval: 1400; onTriggered: root.copied = false }
    Timer { id: flightFallback; interval: 1500; onTriggered: root.startFlight() }

    Process {
        id: capProc
        command: ["bash", root.dir + "capture.sh", root.geom, root.outFile]
        stderr: StdioCollector { id: capErr }
        onExited: code => root.captureDone(code)
    }
    Process { id: actProc }
    Process { id: errNotify }

    FrameAnimation {
        id: sim
        running: root.simOn && (root.mode === "select" || root.mode === "confirm")
        property real acc: 0
        onTriggered: {
            acc += Math.min(frameTime, 0.05);
            var e = 0, n = 0, i;
            while (acc >= 1 / 60 && n < 3) {
                for (i = 0; i < root.ropeList.length; i++)
                    e += root.ropeList[i].step(1 / 60, root.pvx, root.pvy);
                root.pvx *= 0.9;
                root.pvy *= 0.9;
                acc -= 1 / 60;
                n++;
            }
            if (n > 0) for (i = 0; i < root.ropeList.length; i++) root.ropeList[i].buildPath();
            if (e < 0.3 && !root.dragging && Math.abs(root.pvx) + Math.abs(root.pvy) < 5) root.calm++;
            else root.calm = 0;
            if (root.calm > 50) { root.simOn = false; root.calm = 0; }
        }
    }

    Behavior on fade { NumberAnimation { duration: 160 } }

    // confirm: filaments tighten -> cyan pulse races to the brackets -> ring + flash
    SequentialAnimation {
        id: confirmAnim
        NumberAnimation { target: root; property: "tension"; from: 0; to: 1; duration: 170; easing.type: Easing.OutCubic }
        ParallelAnimation {
            NumberAnimation { target: root; property: "pulseT"; from: 0; to: 1; duration: 260; easing.type: Easing.InOutQuad }
            SequentialAnimation {
                PauseAnimation { duration: 190 }
                NumberAnimation { target: root; property: "ringT"; from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }
            }
        }
        ScriptAction { script: root.tryFlight() }
    }
    NumberAnimation { id: flightAnim; target: root; property: "flightT"; from: 0; to: 1; duration: 700; easing.type: Easing.InOutCubic
        onFinished: { infoAnim.restart(); ttlAnim.restart(); } }
    NumberAnimation { id: infoAnim; target: root; property: "infoT"; from: 0; to: 1; duration: 700; easing.type: Easing.OutCubic }
    NumberAnimation { id: ttlAnim; target: root; property: "ttlFrac"; from: 1; to: 0; duration: Config.cardDismissMs
        paused: cardHover.hovered; onFinished: root.dismiss() }
    NumberAnimation { id: exitAnim; target: root; property: "exitT"; from: 0; to: 1; duration: 340; easing.type: Easing.InCubic
        onFinished: root.finish() }

    Connections {
        target: img
        function onStatusChanged() { if (root.pendingFlight && img.status !== Image.Loading) root.startFlight(); }
    }

    // ======================================================================
    //  scene
    // ======================================================================
    Item {
        id: stage
        anchors.fill: parent
        visible: root.mode !== "capturing"
        focus: true
        Keys.onEscapePressed: { if (root.mode === "select") root.cancel(); else if (root.mode === "result") root.dismiss(); }
        Keys.onReturnPressed: root.requestCapture()
        Keys.onEnterPressed: root.requestCapture()

        Item { id: cardMask; x: root.cardX; y: root.cardY; width: root.cardW; height: root.cardH }

        readonly property real dimLevel: root.mode === "result" ? Math.max(0, 1 - root.flightT * 2.5) * 0.7
                                       : (root.mode === "confirm" ? 0.7 * root.fade : root.fade)
        readonly property real hx: root.hasSel ? root.selX : 0
        readonly property real hy: root.hasSel ? root.selY : 0
        readonly property real hw: root.hasSel ? root.selW : 0
        readonly property real hh: root.hasSel ? root.selH : 0

        // ---- smoky dim with a real hole around the selection (4 rects) ----
        Item {
            z: 0
            anchors.fill: parent
            opacity: Config.dimOpacity * stage.dimLevel
            Rectangle { color: Config.smoke; x: 0; y: 0; width: stage.width; height: stage.hy }
            Rectangle { color: Config.smoke; x: 0; y: stage.hy + stage.hh; width: stage.width; height: stage.height - stage.hy - stage.hh }
            Rectangle { color: Config.smoke; x: 0; y: stage.hy; width: stage.hx; height: stage.hh }
            Rectangle { color: Config.smoke; x: stage.hx + stage.hw; y: stage.hy; width: stage.width - stage.hx - stage.hw; height: stage.hh }
        }

        MouseArea {
            z: 1
            anchors.fill: parent
            enabled: root.mode === "select"
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.CrossCursor
            onPressed: mouse => {
                if (mouse.button === Qt.RightButton) { root.cancel(); return; }
                root.pressX = mouse.x; root.pressY = mouse.y;
                root.dragging = true;
                root.hasSel = false;
                root.selX = Math.round(mouse.x); root.selY = Math.round(mouse.y);
                root.selW = 0; root.selH = 0;
                for (var i = 0; i < root.ropeList.length; i++) root.ropeList[i].reset();
                root.trackPointer(mouse.x, mouse.y);
            }
            onPositionChanged: mouse => {
                root.trackPointer(mouse.x, mouse.y);
                if (root.dragging) root.updateSel(mouse.x, mouse.y);
            }
            onReleased: mouse => {
                if (mouse.button !== Qt.LeftButton || !root.dragging) return;
                root.dragging = false;
                if (root.selW < Config.minSize || root.selH < Config.minSize) { root.hasSel = false; root.wake(); return; }
                if (Config.confirmOnRelease) root.requestCapture();
            }
        }

        // ---- crosshair (before dragging) ---------------------------------
        Item {
            z: 1
            anchors.fill: parent
            opacity: (root.mode === "select" && !root.hasSel && !root.dragging) ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 140 } }
            Rectangle { x: 0; y: root.curY; width: stage.width; height: 1; color: Config.alpha(Config.cyan, 0.16) }
            Rectangle { x: root.curX; y: 0; width: 1; height: stage.height; color: Config.alpha(Config.cyan, 0.16) }
        }

        // ---- selection outline, thirds, edge ticks -----------------------
        Item {
            z: 1
            x: root.selX; y: root.selY; width: root.selW; height: root.selH
            visible: root.hasSel && root.mode !== "result"
            opacity: root.mode === "confirm" ? 1 - root.clamp01(root.ringT * 1.2) * 0.4 : 1
            Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: Config.alpha(Config.cyan, 0.55) }
            Rectangle { visible: parent.width > 150; x: parent.width / 3; y: 0; width: 1; height: parent.height; color: Qt.rgba(1, 1, 1, 0.09) }
            Rectangle { visible: parent.width > 150; x: parent.width * 2 / 3; y: 0; width: 1; height: parent.height; color: Qt.rgba(1, 1, 1, 0.09) }
            Rectangle { visible: parent.height > 150; y: parent.height / 3; x: 0; height: 1; width: parent.width; color: Qt.rgba(1, 1, 1, 0.09) }
            Rectangle { visible: parent.height > 150; y: parent.height * 2 / 3; x: 0; height: 1; width: parent.width; color: Qt.rgba(1, 1, 1, 0.09) }
            Rectangle { x: parent.width / 2 - 6; y: -2; width: 12; height: 3; radius: 1.5; color: Config.alpha(Config.cyan, 0.8) }
            Rectangle { x: parent.width / 2 - 6; y: parent.height - 1; width: 12; height: 3; radius: 1.5; color: Config.alpha(Config.cyan, 0.8) }
            Rectangle { y: parent.height / 2 - 6; x: -2; height: 12; width: 3; radius: 1.5; color: Config.alpha(Config.cyan, 0.8) }
            Rectangle { y: parent.height / 2 - 6; x: parent.width - 1; height: 12; width: 3; radius: 1.5; color: Config.alpha(Config.cyan, 0.8) }
        }

        // ---- four physical filaments -------------------------------------
        readonly property real ropeOp: (root.hasSel ? 1 : 0) * (root.mode === "result" ? 1 - root.clamp01(root.flightT * 4) : 1)
        Rope {
            id: r0; z: 2; anchors.fill: parent
            anchorPt: Qt.point(0, 0); targetPt: Qt.point(root.selX, root.selY)
            slack: 1.03 - 0.06 * root.tension; tension: root.tension; ropeOpacity: stage.ropeOp
            pulse: root.mode === "confirm" ? root.pulseT : -1
            onTargetPtChanged: root.wake()
        }
        Rope {
            id: r1; z: 2; anchors.fill: parent
            anchorPt: Qt.point(stage.width, 0); targetPt: Qt.point(root.selX + root.selW, root.selY)
            slack: 1.03 - 0.06 * root.tension; tension: root.tension; ropeOpacity: stage.ropeOp
            pulse: root.mode === "confirm" ? root.pulseT : -1
            onTargetPtChanged: root.wake()
        }
        Rope {
            id: r2; z: 2; anchors.fill: parent
            anchorPt: Qt.point(stage.width, stage.height); targetPt: Qt.point(root.selX + root.selW, root.selY + root.selH)
            slack: 1.03 - 0.06 * root.tension; tension: root.tension; ropeOpacity: stage.ropeOp
            pulse: root.mode === "confirm" ? root.pulseT : -1
            onTargetPtChanged: root.wake()
        }
        Rope {
            id: r3; z: 2; anchors.fill: parent
            anchorPt: Qt.point(0, stage.height); targetPt: Qt.point(root.selX, root.selY + root.selH)
            slack: 1.03 - 0.06 * root.tension; tension: root.tension; ropeOpacity: stage.ropeOp
            pulse: root.mode === "confirm" ? root.pulseT : -1
            onTargetPtChanged: root.wake()
        }

        // ---- thumbnail + result card (one layer, so it can "swallow" into the dock) ----
        Item {
            id: exitLayer
            z: 5
            anchors.fill: parent
            visible: root.mode === "confirm" || root.mode === "result"
            opacity: 1 - root.exitT
            transform: Scale {
                origin.x: stage.width / 2
                origin.y: stage.height - 48
                xScale: 1 - 0.7 * root.exitT
                yScale: 1 - 0.7 * root.exitT
            }

            // motion echoes
            Repeater {
                model: 3
                Rectangle {
                    required property int index
                    readonly property real tt: Math.max(0, root.flightT - 0.07 * (index + 1))
                    visible: root.flightT > 0.02 && root.flightT < 0.98
                    x: root.lerp(root.selX, root.slotX, tt)
                    y: root.lerp(root.selY, root.slotY, tt) - 70 * Math.sin(Math.PI * tt)
                    width: root.lerp(root.selW, root.slotW, tt)
                    height: root.lerp(root.selH, root.slotH, tt)
                    radius: 6
                    color: Config.alpha(Config.cyan, 0.08 - index * 0.02)
                    border.width: 1
                    border.color: Config.alpha(Config.cyan, 0.3 - index * 0.08)
                }
            }

            // result card
            Item {
                id: card
                x: root.cardX; y: root.cardY; width: root.cardW; height: root.cardH
                visible: root.cardT > 0.001
                opacity: root.clamp01(root.cardT * 1.5)
                scale: 0.85 + 0.15 * root.easeOutBack(root.cardT)
                transformOrigin: Item.Bottom

                HoverHandler { id: cardHover }

                Glass { anchors.fill: parent; radius: 22; glass: 0.72 }

                // info column
                Item {
                    x: 16 + root.slotW + 20
                    y: 16
                    width: root.cardW - x - 16
                    height: root.contentH

                    readonly property real t0: root.clamp01(root.infoT / 0.4)
                    readonly property real t1: root.clamp01((root.infoT - 0.12) / 0.4)
                    readonly property real t2: root.clamp01((root.infoT - 0.22) / 0.4)
                    readonly property real t3: root.clamp01((root.infoT - 0.32) / 0.5)

                    Text {
                        opacity: parent.t0; y: (1 - parent.t0) * 8
                        text: "CAPTURED"
                        color: Config.cyan
                        font.family: Config.mono; font.pixelSize: 10; font.letterSpacing: 3.2; font.weight: Font.Medium
                    }
                    Text {
                        opacity: parent.t1; y: 20 + (1 - parent.t1) * 8
                        width: parent.width
                        elide: Text.ElideMiddle
                        text: root.outFile.substring(root.outFile.lastIndexOf("/") + 1)
                        color: Config.white
                        font.family: Config.mono; font.pixelSize: 13
                    }
                    Text {
                        opacity: parent.t2; y: 42 + (1 - parent.t2) * 8
                        text: root.selW + " × " + root.selH + "   ·   " + (copyBtn.hovered ? "copy to clipboard"
                              : (openBtn.hovered ? "open in viewer" : (revealBtn.hovered ? "reveal in file manager" : "saved")))
                        color: Config.sub
                        font.family: Config.mono; font.pixelSize: 10; font.letterSpacing: 0.4
                    }
                    Row {
                        opacity: parent.t3; y: 70 + (1 - parent.t3) * 10
                        spacing: 8
                        GlassButton { id: copyBtn; text: root.copied ? "Copied" : "Copy"; glyph: root.copied ? "check" : "copy"
                                      tint: root.copied ? Config.ok : Config.cyan; onClicked: root.doCopy() }
                        GlassButton { id: openBtn; text: "Open"; glyph: "open"; onClicked: root.doOpen() }
                        GlassButton { id: revealBtn; text: "Reveal"; glyph: "folder"; tint: Config.blue; onClicked: root.doReveal() }
                    }
                }

                // close
                Item {
                    x: parent.width - 34; y: 10; width: 22; height: 22
                    opacity: root.infoT
                    Glyph { anchors.centerIn: parent; width: 12; height: 12; kind: "close"
                            color: closeMa.containsMouse ? Config.white : Config.sub
                            scale: closeMa.containsMouse ? 1.25 : 1
                            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } } }
                    MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.dismiss() }
                }

                // auto-dismiss line (pauses while hovered)
                Rectangle {
                    x: 20; y: parent.height - 9
                    height: 2; radius: 1
                    width: (parent.width - 40) * root.ttlFrac
                    color: Config.alpha(Config.cyan, 0.55)
                    opacity: root.infoT
                }
            }

            // the captured pixels: sits on the selection, then flies to the card slot
            Item {
                id: fly
                readonly property real t: root.flightT
                x: root.lerp(root.selX, root.slotX, t)
                y: root.lerp(root.selY, root.slotY, t) - 70 * Math.sin(Math.PI * t)
                width: root.lerp(root.selW, root.slotW, t)
                height: root.lerp(root.selH, root.slotH, t)
                rotation: -3 * Math.sin(Math.PI * t)
                opacity: img.status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 140 } }

                Image {
                    id: img
                    anchors.fill: parent
                    source: (root.outFile !== "" && root.mode !== "idle") ? "file://" + root.outFile : ""
                    asynchronous: true
                    cache: false
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 900
                    smooth: true
                }
                Rectangle {
                    anchors.fill: parent
                    radius: root.lerp(0, 8, fly.t)
                    color: "transparent"
                    border.width: 1
                    border.color: Config.alpha(Config.cyan, 0.4 + 0.3 * fly.t)
                }
                Rectangle {   // shutter flash
                    anchors.fill: parent
                    color: Config.white
                    opacity: root.mode === "confirm" ? 0.22 * Math.sin(Math.PI * root.ringT) : 0
                }
            }
        }

        // ---- brackets (independent, exactly on the real corners) ---------
        readonly property real bracketOp: root.mode === "result" ? 1 - root.clamp01(root.flightT * 5) : 1
        readonly property real arm: Math.max(8, Math.min(24, Math.min(root.selW, root.selH) / 3 + 6))
        readonly property real flash: Math.sin(Math.PI * root.ringT)
        Bracket { z: 6; corner: 0; x: root.selX; y: root.selY; armLen: stage.arm; boost: stage.flash
                  visible: root.hasSel; opacity: stage.bracketOp }
        Bracket { z: 6; corner: 1; x: root.selX + root.selW; y: root.selY; armLen: stage.arm; boost: stage.flash
                  visible: root.hasSel; opacity: stage.bracketOp }
        Bracket { z: 6; corner: 2; x: root.selX + root.selW; y: root.selY + root.selH; armLen: stage.arm; boost: stage.flash
                  visible: root.hasSel; opacity: stage.bracketOp }
        Bracket { z: 6; corner: 3; x: root.selX; y: root.selY + root.selH; armLen: stage.arm; boost: stage.flash
                  visible: root.hasSel; opacity: stage.bracketOp }

        // ---- confirm ring ------------------------------------------------
        Item {
            z: 7
            visible: root.mode === "confirm" && root.ringT > 0 && root.ringT < 1
            Rectangle {
                x: root.selX - root.ringT * 46; y: root.selY - root.ringT * 46
                width: root.selW + root.ringT * 92; height: root.selH + root.ringT * 92
                radius: root.ringT * 20
                color: "transparent"; border.width: 2
                border.color: Config.alpha(Config.cyan, 0.9 * (1 - root.ringT))
            }
            Rectangle {
                x: root.selX - root.ringT * 84; y: root.selY - root.ringT * 84
                width: root.selW + root.ringT * 168; height: root.selH + root.ringT * 168
                radius: root.ringT * 34
                color: "transparent"; border.width: 1
                border.color: Config.alpha(Config.blue, 0.5 * (1 - root.ringT))
            }
        }

        // ---- HUD ---------------------------------------------------------
        Glass {
            id: hud
            z: 8
            width: hudCol.implicitWidth + 28
            height: 46
            radius: 13
            readonly property real wantX: {
                var bx = root.hasSel ? root.selX + root.selW : root.curX;
                var by = root.hasSel ? root.selY + root.selH : root.curY;
                var nx = bx + 16;
                return (nx + width > stage.width - 8) ? Math.max(8, bx - width - 16) : nx;
            }
            readonly property real wantY: {
                var by = root.hasSel ? root.selY + root.selH : root.curY;
                var ny = by + 16;
                return (ny + height > stage.height - 8) ? Math.max(8, by - height - 16) : ny;
            }
            x: wantX
            y: wantY
            Behavior on x { SpringAnimation { spring: 3.2; damping: 0.34; epsilon: 0.05 } }
            Behavior on y { SpringAnimation { spring: 3.2; damping: 0.34; epsilon: 0.05 } }
            opacity: (root.mode === "select" || root.mode === "confirm") ? 1 : 0
            scale: root.dragging ? 1.0 : 0.96
            Behavior on opacity { NumberAnimation { duration: 160 } }
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

            Column {
                id: hudCol
                anchors.centerIn: parent
                spacing: 3
                Text {
                    text: root.hasSel ? root.selW + " × " + root.selH : Math.round(root.curX) + ", " + Math.round(root.curY)
                    color: Config.white
                    font.family: Config.mono; font.pixelSize: 14; font.weight: Font.Medium
                }
                Text {
                    text: root.hasSel ? "x " + Math.round(root.ox + root.selX) + "   y " + Math.round(root.oy + root.selY) : "drag to select"
                    color: Config.alpha(Config.cyan, 0.85)
                    font.family: Config.mono; font.pixelSize: 10; font.letterSpacing: 1
                }
            }
        }

        // ---- banner ------------------------------------------------------
        Item {
            z: 8
            id: banner
            property real bt: (root.mode === "select" && !root.hasSel && !root.dragging) ? 1 : 0
            Behavior on bt { NumberAnimation { duration: 420; easing.type: Easing.OutBack } }
            width: 360; height: 54
            x: (stage.width - width) / 2
            y: 28 - (1 - bt) * 44
            opacity: root.clamp01(bt)
            visible: opacity > 0.01

            Rectangle { x: -150; y: 27; width: 132; height: 1
                gradient: Gradient { orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 1; color: Config.alpha(Config.cyan, 0.5) } } }
            Rectangle { x: parent.width + 18; y: 27; width: 132; height: 1
                gradient: Gradient { orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Config.alpha(Config.cyan, 0.5) }
                    GradientStop { position: 1; color: "transparent" } } }
            Glass {
                anchors.fill: parent
                radius: 16
                Column {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "NYX // PHANTOM CAPTURE"
                        color: Config.cyan
                        font.family: Config.mono; font.pixelSize: 12; font.letterSpacing: 3.4; font.weight: Font.Medium
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "DRAG TO SELECT   ·   ESC TO CANCEL"
                        color: Config.sub
                        font.family: Config.mono; font.pixelSize: 9; font.letterSpacing: 2
                    }
                }
            }
        }
    }
}
