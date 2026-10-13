import QtQuick

// kind: copy | open | folder | check | close
Canvas {
    id: c
    property string kind: "copy"
    property color color: "white"
    property real lw: 1.6
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
        var w = width, h = height;
        ctx.strokeStyle = c.color;
        ctx.lineWidth = c.lw;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.beginPath();
        if (kind === "copy") {
            ctx.moveTo(w * .30, h * .30); ctx.lineTo(w * .30, h * .12); ctx.lineTo(w * .88, h * .12);
            ctx.lineTo(w * .88, h * .70); ctx.lineTo(w * .70, h * .70);
            ctx.moveTo(w * .12, h * .30); ctx.lineTo(w * .70, h * .30); ctx.lineTo(w * .70, h * .88);
            ctx.lineTo(w * .12, h * .88); ctx.closePath();
        } else if (kind === "open") {
            ctx.moveTo(w * .78, h * .58); ctx.lineTo(w * .78, h * .84); ctx.lineTo(w * .14, h * .84);
            ctx.lineTo(w * .14, h * .22); ctx.lineTo(w * .40, h * .22);
            ctx.moveTo(w * .50, h * .50); ctx.lineTo(w * .88, h * .12);
            ctx.moveTo(w * .60, h * .12); ctx.lineTo(w * .88, h * .12); ctx.lineTo(w * .88, h * .40);
        } else if (kind === "folder") {
            ctx.moveTo(w * .10, h * .26); ctx.lineTo(w * .38, h * .26); ctx.lineTo(w * .48, h * .38);
            ctx.lineTo(w * .90, h * .38); ctx.lineTo(w * .90, h * .80); ctx.lineTo(w * .10, h * .80);
            ctx.closePath();
        } else if (kind === "check") {
            ctx.moveTo(w * .18, h * .54); ctx.lineTo(w * .42, h * .78); ctx.lineTo(w * .84, h * .26);
        } else if (kind === "close") {
            ctx.moveTo(w * .24, h * .24); ctx.lineTo(w * .76, h * .76);
            ctx.moveTo(w * .76, h * .24); ctx.lineTo(w * .24, h * .76);
        }
        ctx.stroke();
    }
}
