import QtQuick

// Canvas-drawn icons (no icon font needed).
// kind: gear | cross | check | apply | grid | drop | spark
Canvas {
    id: c
    property string kind: "gear"
    property color color: "white"
    property real lw: 2

    implicitWidth: 16
    implicitHeight: 16
    antialiasing: true

    onColorChanged: requestPaint()
    onKindChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        var w = width, h = height, cx = w / 2, cy = h / 2;
        ctx.strokeStyle = c.color;
        ctx.fillStyle = c.color;
        ctx.lineWidth = c.lw;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        if (kind === "gear") {
            var teeth = 8, R = w * 0.47, r = w * 0.34, step = 2 * Math.PI / teeth;
            ctx.beginPath();
            for (var i = 0; i < teeth; i++) {
                var a = i * step;
                var p = [[r, a - step * 0.25], [R, a - step * 0.16], [R, a + step * 0.16], [r, a + step * 0.25]];
                for (var j = 0; j < p.length; j++) {
                    var x = cx + p[j][0] * Math.cos(p[j][1]);
                    var y = cy + p[j][0] * Math.sin(p[j][1]);
                    if (i === 0 && j === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
                }
            }
            ctx.closePath();
            ctx.moveTo(cx + w * 0.15, cy);
            ctx.arc(cx, cy, w * 0.15, 0, 2 * Math.PI, true);
            ctx.fill();
        } else if (kind === "cross") {
            ctx.beginPath();
            ctx.moveTo(w * 0.25, h * 0.25); ctx.lineTo(w * 0.75, h * 0.75);
            ctx.moveTo(w * 0.75, h * 0.25); ctx.lineTo(w * 0.25, h * 0.75);
            ctx.stroke();
        } else if (kind === "check") {
            ctx.beginPath();
            ctx.moveTo(w * 0.2, h * 0.55); ctx.lineTo(w * 0.42, h * 0.76); ctx.lineTo(w * 0.8, h * 0.28);
            ctx.stroke();
        } else if (kind === "apply") {
            var rad = w * 0.3, a0 = -0.15 * Math.PI, a1 = a0 + 1.5 * Math.PI;
            ctx.beginPath();
            ctx.arc(cx, cy, rad, a0, a1, false);
            ctx.stroke();
            var ex = cx + rad * Math.cos(a1), ey = cy + rad * Math.sin(a1);
            var nx = Math.cos(a1), ny = Math.sin(a1), tx = -Math.sin(a1), ty = Math.cos(a1);
            var k = w * 0.15, s = w * 0.2;
            ctx.beginPath();
            ctx.moveTo(ex + tx * s, ey + ty * s);
            ctx.lineTo(ex + nx * k, ey + ny * k);
            ctx.lineTo(ex - nx * k, ey - ny * k);
            ctx.closePath();
            ctx.fill();
        } else if (kind === "grid") {
            var g = w * 0.12, sq = (w - 3 * g) / 2;
            for (var gx = 0; gx < 2; gx++)
                for (var gy = 0; gy < 2; gy++)
                    ctx.fillRect(g + gx * (sq + g), g + gy * (sq + g), sq, sq);
        } else if (kind === "drop") {
            ctx.beginPath();
            ctx.moveTo(cx, h * 0.1);
            ctx.bezierCurveTo(w * 0.9, h * 0.5, w * 0.82, h * 0.9, cx, h * 0.9);
            ctx.bezierCurveTo(w * 0.18, h * 0.9, w * 0.1, h * 0.5, cx, h * 0.1);
            ctx.closePath();
            ctx.fill();
        } else if (kind === "spark") {
            ctx.beginPath();
            for (var q = 0; q < 8; q++) {
                var ang = q * Math.PI / 4 - Math.PI / 2;
                var rr = (q % 2 === 0) ? w * 0.48 : w * 0.14;
                var px = cx + rr * Math.cos(ang), py = cy + rr * Math.sin(ang);
                if (q === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
            }
            ctx.closePath();
            ctx.fill();
        }
    }
}
