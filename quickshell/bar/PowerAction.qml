import QtQuick

Rectangle {
    id: btn
    property string icon: ""
    property string label: ""
    property color accent: "white"
    signal activated()

    width: 110
    height: 110
    radius: 16
    color: area.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.2) : Theme.surface
    border.width: 1
    border.color: area.containsMouse ? accent : Theme.border
    scale: area.pressed ? 0.95 : (area.containsMouse ? 1.06 : 1)

    Behavior on color        { ColorAnimation { duration: 220 } }
    Behavior on border.color { ColorAnimation { duration: 220 } }
    Behavior on scale        { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    Column {
        anchors.centerIn: parent
        spacing: 10

        Text {
            id: glyph
            anchors.horizontalCenter: parent.horizontalCenter
            text: btn.icon
            color: btn.accent
            font { family: Theme.iconFont; pixelSize: 34 }
            transformOrigin: Item.Center
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: btn.label
            color: btn.accent
            font { family: Theme.font; pixelSize: 11; bold: true }
        }
    }

    // quick spin of the icon each time the cursor enters
    NumberAnimation { id: spin; target: glyph; property: "rotation"; from: 0; to: 360; duration: 420; easing.type: Easing.OutCubic }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: if (containsMouse) spin.restart()
        onClicked: btn.activated()
    }
}
