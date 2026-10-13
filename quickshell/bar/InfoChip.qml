import QtQuick
import QtQuick.Layouts

Rectangle {
    id: chip
    property string icon: ""
    property string label: ""
    property color accent: Theme.accent

    implicitHeight: 32
    implicitWidth: row.implicitWidth + 24
    radius: 11
    color: hit.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.18) : Theme.surface
    border.width: 1
    border.color: hit.containsMouse ? accent : Theme.border
    scale: hit.containsMouse ? 1.04 : 1
    Behavior on color        { ColorAnimation { duration: 180 } }
    Behavior on border.color { ColorAnimation { duration: 180 } }
    Behavior on scale        { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    RowLayout {
        id: row
        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
        spacing: 8
        Text {
            text: chip.icon
            color: chip.accent
            font { family: Theme.iconFont; pixelSize: 14 }
        }
        Text {
            Layout.fillWidth: true
            text: chip.label
            elide: Text.ElideRight
            color: Theme.text
            font { family: "Montserrat"; pixelSize: 11; weight: Font.Medium }
        }
    }
    MouseArea { id: hit; anchors.fill: parent; hoverEnabled: true }
}
