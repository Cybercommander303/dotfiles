import QtQuick
import QtQuick.Shapes

// A spring-physics filament (Verlet chain) from a fixed screen corner to a bracket.
// The parent drives step(); the rope sleeps when nothing moves.
Item {
    id: r
    property point anchorPt: Qt.point(0, 0)
    property point targetPt: Qt.point(0, 0)
    property real slack: 1.03          // rest length / straight distance (<1 = taut)
    property real tension: 0           // 0..1, whitens + thins the core on confirm
    property real pulse: -1            // 0..1 travelling pulse, <0 hidden
    property real ropeOpacity: 1

    readonly property int n: 14
    property var px: []
    property var py: []
    property var ox: []
    property var oy: []
    property var pts: []
    property real pulseX: 0
    property real pulseY: 0

    visible: ropeOpacity > 0.01

    function reset() {
        var N = n, ax = anchorPt.x, ay = anchorPt.y, tx = targetPt.x, ty = targetPt.y;
        var a = [], b = [], c = [], d = [];
        for (var i = 0; i < N; i++) {
            var t = i / (N - 1), x = ax + (tx - ax) * t, y = ay + (ty - ay) * t;
            a.push(x); b.push(y); c.push(x); d.push(y);
        }
        px = a; py = b; ox = c; oy = d;
        buildPath();
    }

    // returns "energy" (total movement this step) so the parent can put the sim to sleep
    function step(dt, vx, vy) {
        var N = n;
        if (px.length !== N) reset();
        var ax = anchorPt.x, ay = anchorPt.y, tx = targetPt.x, ty = targetPt.y;
        var ddx0 = tx - ax, ddy0 = ty - ay;
        var dist = Math.sqrt(ddx0 * ddx0 + ddy0 * ddy0);
        var seg = dist * slack / (N - 1);
        var g = 1500 * dt * dt;
        var damp = 0.982;
        var e = 0;

        px[0] = ax; py[0] = ay; px[N - 1] = tx; py[N - 1] = ty;

        for (var i = 1; i < N - 1; i++) {
            var w = Math.sin(Math.PI * i / (N - 1));
            var cx = px[i], cy = py[i];
            // inertia + gravity + a little drag against the pointer velocity
            var nx_ = cx + (cx - ox[i]) * damp - vx * dt * 0.025 * w;
            var ny_ = cy + (cy - oy[i]) * damp - vy * dt * 0.025 * w + g;
            ox[i] = cx; oy[i] = cy;
            px[i] = nx_; py[i] = ny_;
            e += Math.abs(nx_ - cx) + Math.abs(ny_ - cy);
        }

        // soft distance constraints -> the rope can stretch while the pointer moves fast
        for (var it = 0; it < 5; it++) {
            px[0] = ax; py[0] = ay; px[N - 1] = tx; py[N - 1] = ty;
            for (var j = 0; j < N - 1; j++) {
                var dx = px[j + 1] - px[j], dy = py[j + 1] - py[j];
                var d = Math.sqrt(dx * dx + dy * dy);
                if (d < 0.0001) continue;
                var diff = (d - seg) / d * 0.62;
                var w1 = (j === 0) ? 0 : ((j + 1 === N - 1) ? 1 : 0.5);
                var w2 = (j === 0) ? 1 : ((j + 1 === N - 1) ? 0 : 0.5);
                px[j] += dx * diff * w1; py[j] += dy * diff * w1;
                px[j + 1] -= dx * diff * w2; py[j + 1] -= dy * diff * w2;
            }
        }
        return e;
    }

    // Catmull-Rom through the chain nodes -> smooth curve
    function buildPath() {
        var N = n, out = [], sub = 3;
        if (px.length !== N) return;
        for (var i = 0; i < N - 1; i++) {
            var p0 = Math.max(0, i - 1), p1 = i, p2 = i + 1, p3 = Math.min(N - 1, i + 2);
            for (var s = 0; s < sub; s++) {
                var t = s / sub, t2 = t * t, t3 = t2 * t;
                var x = 0.5 * ((2 * px[p1]) + (-px[p0] + px[p2]) * t
                    + (2 * px[p0] - 5 * px[p1] + 4 * px[p2] - px[p3]) * t2
                    + (-px[p0] + 3 * px[p1] - 3 * px[p2] + px[p3]) * t3);
                var y = 0.5 * ((2 * py[p1]) + (-py[p0] + py[p2]) * t
                    + (2 * py[p0] - 5 * py[p1] + 4 * py[p2] - py[p3]) * t2
                    + (-py[p0] + 3 * py[p1] - 3 * py[p2] + py[p3]) * t3);
                out.push(Qt.point(x, y));
            }
        }
        out.push(Qt.point(px[N - 1], py[N - 1]));
        pts = out;
        glowLine.path = out;
        midLine.path = out;
        coreLine.path = out;
        updatePulse();
    }

    function updatePulse() {
        if (pulse < 0 || pts.length < 2) return;
        var f = Math.max(0, Math.min(1, pulse)) * (pts.length - 1);
        var i = Math.min(pts.length - 2, Math.floor(f)), t = f - i;
        var a = pts[i], b = pts[i + 1];
        pulseX = a.x + (b.x - a.x) * t;
        pulseY = a.y + (b.y - a.y) * t;
    }
    onPulseChanged: updatePulse()

    Shape {
        anchors.fill: parent
        opacity: r.ropeOpacity
        // To get smoother edges on Qt >= 6.6 you can add:  preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: Config.alpha(Config.cyan, 0.09)
            strokeWidth: 9
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline { id: glowLine }
        }
        ShapePath {
            strokeColor: Config.alpha(Config.cyan, 0.2 + 0.15 * r.tension)
            strokeWidth: 3.5
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline { id: midLine }
        }
        ShapePath {
            strokeColor: Qt.rgba(0.404 + 0.569 * r.tension, 0.91 + 0.07 * r.tension, 0.976 + 0.012 * r.tension, 0.6 + 0.4 * r.tension)
            strokeWidth: 1.2 + 0.6 * r.tension
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline { id: coreLine }
        }
    }

    // travelling pulse
    Rectangle {
        visible: r.pulse >= 0 && r.pulse < 1
        x: r.pulseX - 12; y: r.pulseY - 12; width: 24; height: 24; radius: 12
        color: Config.alpha(Config.cyan, 0.28)
    }
    Rectangle {
        visible: r.pulse >= 0 && r.pulse < 1
        x: r.pulseX - 3; y: r.pulseY - 3; width: 6; height: 6; radius: 3
        color: Config.white
    }
}
