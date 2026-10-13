import QtQuick

// A bell that swings like it is ringing, then rests for a moment.
Item {
    id: bell
    property bool ringing: true
    property bool muted: false
    width: 60
    height: 64

    Text {
        id: glyph
        anchors.horizontalCenter: parent.horizontalCenter
        y: 4
        text: bell.muted ? "\uf1f6" : "\uf0f3"
        color: bell.muted ? Theme.muted : Theme.bulb
        font { family: Theme.iconFont; pixelSize: 44 }
        transformOrigin: Item.Top                       // swings from the top, like a hanging bell
        Behavior on color { ColorAnimation { duration: 250 } }
    }

    SequentialAnimation {
        running: bell.ringing && !bell.muted
        loops: Animation.Infinite
        NumberAnimation { target: glyph; property: "rotation"; to: -26; duration: 90;  easing.type: Easing.OutSine }
        NumberAnimation { target: glyph; property: "rotation"; to: 22;  duration: 170; easing.type: Easing.InOutSine }
        NumberAnimation { target: glyph; property: "rotation"; to: -17; duration: 150; easing.type: Easing.InOutSine }
        NumberAnimation { target: glyph; property: "rotation"; to: 13;  duration: 130; easing.type: Easing.InOutSine }
        NumberAnimation { target: glyph; property: "rotation"; to: -8;  duration: 110; easing.type: Easing.InOutSine }
        NumberAnimation { target: glyph; property: "rotation"; to: 5;   duration: 90;  easing.type: Easing.InOutSine }
        NumberAnimation { target: glyph; property: "rotation"; to: 0;   duration: 80;  easing.type: Easing.OutSine }
        PauseAnimation { duration: 2400 }
    }
}
