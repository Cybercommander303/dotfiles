import QtQuick

// Miniature desktop that redraws live from HyprSettings.
Rectangle {
    id: p
    radius: 18
    color: Theme.panel
    border.width: 1
    border.color: Theme.border

    readonly property string sig: [
        HyprSettings.gapsIn, HyprSettings.gapsOut, HyprSettings.borderSize, HyprSettings.rounding,
        HyprSettings.activeA, HyprSettings.activeB, HyprSettings.inactive, HyprSettings.angle,
        HyprSettings.activeOpacity, HyprSettings.inactiveOpacity, HyprSettings.shadowEnabled
    ].join("|")
    onSigChanged: cv.requestPaint()

    Text {
        x: 18
        y: 14
        text: "Live preview"
        color: Theme.accent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fsHead
        font.weight: Font.Bold
    }

    Canvas {
        id: cv
        x: 14
        y: 46
        width: parent.width - 28
        height: parent.height - 60
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        function rr(ctx, x, y, w, h, r) {
            r = Math.max(0, Math.min(r, w / 2, h / 2));
            ctx.beginPath();
            ctx.moveTo(x + r, y);
            ctx.lineTo(x + w - r, y);
            ctx.arcTo(x + w, y, x + w, y + r, r);
            ctx.lineTo(x + w, y + h - r);
            ctx.arcTo(x + w, y + h, x + w - r, y + h, r);
            ctx.lineTo(x + r, y + h);
            ctx.arcTo(x, y + h, x, y + h - r, r);
            ctx.lineTo(x, y + r);
            ctx.arcTo(x, y, x + r, y, r);
            ctx.closePath();
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var W = width, H = height;
            if (W < 20 || H < 20) return;

            // wallpaper
            rr(ctx, 0, 0, W, H, 12);
            var wg = ctx.createLinearGradient(0, 0, W, H);
            wg.addColorStop(0, "#3a2f7a");
            wg.addColorStop(1, "#0f6a78");
            ctx.fillStyle = wg;
            ctx.fill();

            var S = W / 380 * 0.9;
            var go = Math.min(HyprSettings.gapsOut * S, W * 0.18);
            var gi = Math.min(HyprSettings.gapsIn * S, W * 0.08);
            var lw = HyprSettings.borderSize * S;
            var rad = HyprSettings.rounding * S;
            var ax = go, ay = go, aw = W - 2 * go, ah = H - 2 * go;
            var lwW = (aw - gi) * 0.56, rw = aw - lwW - gi, rh = (ah - gi) / 2;

            var wins = [
                { x: ax + lwW + gi, y: ay, w: rw, h: rh, act: false },
                { x: ax + lwW + gi, y: ay + rh + gi, w: rw, h: rh, act: false },
                { x: ax, y: ay, w: lwW, h: ah, act: true }
            ];

            var th = HyprSettings.angle * Math.PI / 180, dx = Math.cos(th), dy = Math.sin(th);

            for (var i = 0; i < wins.length; i++) {
                var o = wins[i];
                if (o.w < 8 || o.h < 8) continue;

                ctx.save();
                if (HyprSettings.shadowEnabled) {
                    ctx.shadowColor = "rgba(0,0,0,0.55)";
                    ctx.shadowBlur = 14;
                    ctx.shadowOffsetY = 4;
                }
                ctx.globalAlpha = o.act ? HyprSettings.activeOpacity : HyprSettings.inactiveOpacity;
                rr(ctx, o.x, o.y, o.w, o.h, rad);
                ctx.fillStyle = "#1d2033";
                ctx.fill();
                ctx.restore();

                // fake window content
                ctx.fillStyle = "rgba(255,255,255,0.14)";
                var lx = o.x + Math.max(10, rad * 0.8), ly = o.y + Math.max(12, rad * 0.8);
                for (var k = 0; k < 3; k++) {
                    var lh = 5, lwid = (o.w - 2 * (lx - o.x)) * (k === 0 ? 0.55 : (k === 1 ? 0.9 : 0.7));
                    if (lwid > 4 && ly + k * 11 + lh < o.y + o.h - 6) {
                        rr(ctx, lx, ly + k * 11, lwid, lh, 2.5);
                        ctx.fill();
                    }
                }

                if (lw > 0.2) {
                    ctx.lineWidth = lw;
                    if (o.act) {
                        var cx = o.x + o.w / 2, cy = o.y + o.h / 2;
                        var L = (Math.abs(o.w * dx) + Math.abs(o.h * dy)) / 2;
                        var g = ctx.createLinearGradient(cx - dx * L, cy - dy * L, cx + dx * L, cy + dy * L);
                        g.addColorStop(0, "#" + HyprSettings.activeA);
                        g.addColorStop(1, "#" + HyprSettings.activeB);
                        ctx.strokeStyle = g;
                    } else {
                        ctx.strokeStyle = "#" + HyprSettings.inactive;
                    }
                    rr(ctx, o.x + lw / 2, o.y + lw / 2, o.w - lw, o.h - lw, Math.max(0, rad - lw / 2));
                    ctx.stroke();
                }
            }
        }
    }
}
