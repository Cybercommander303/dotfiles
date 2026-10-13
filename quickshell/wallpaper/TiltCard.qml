import QtQuick

// A card that fades/scales in and out, and leans toward whichever corner the cursor is near.
// Put your content inside it:  TiltCard { shown: ...; width: ...; height: ...; <children> }
Rectangle {
    id: card
    property bool shown: false
    property real tilt: 10                 // max lean in degrees. Negative number = lean the other way

    anchors.centerIn: parent
    anchors.verticalCenterOffset: shown ? -20 : 4
    radius: Theme.radius + 8
    color: Theme.bg
    border.color: Theme.border
    border.width: 1

    // ---- open / close ----
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.94
    Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
    Behavior on scale   { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
    Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

    // swallow clicks so the "click outside to close" area behind the card doesn't fire
    MouseArea { anchors.fill: parent }

    // ---- cursor tracking (sits on top of everything but lets clicks through) ----
    MouseArea {
        id: tracker
        anchors.fill: parent
        z: 100
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    // -1..1 across the card; (-1,-1) = top-left corner, (1,1) = bottom-right corner
    readonly property real nx: tracker.containsMouse ? Math.max(-1, Math.min(1, (tracker.mouseX - width  / 2) / (width  / 2))) : 0
    readonly property real ny: tracker.containsMouse ? Math.max(-1, Math.min(1, (tracker.mouseY - height / 2) / (height / 2))) : 0

    // the corner nearest the cursor leans toward you
    property real angleX: ny * tilt
    property real angleY: -nx * tilt
    Behavior on angleX { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on angleY { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    transform: [
        Rotation { origin.x: card.width / 2; origin.y: card.height / 2; axis { x: 0; y: 1; z: 0 } angle: card.angleY },
        Rotation { origin.x: card.width / 2; origin.y: card.height / 2; axis { x: 1; y: 0; z: 0 } angle: card.angleX }
    ]
}
