import QtQuick
import QtQuick.Layouts

Rectangle {
    id: btn
    property string icon: ""
    property string label: ""
    property color accent: Theme.globe
    signal clicked()

    implicitWidth: content.implicitWidth + 28
    implicitHeight: 34
    radius: 10
    color: area.containsMouse ? accent : Theme.surface
    border.color: accent
    border.width: 1
    scale: area.pressed ? 0.95 : (area.containsMouse ? 1.05 : 1)

    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 8

        Text {
            visible: btn.icon !== ""
            text: btn.icon
            color: area.containsMouse ? Theme.darkText : btn.accent
            font { family: Theme.iconFont; pixelSize: 14 }
            Behavior on color { ColorAnimation { duration: 200 } }
        }
        Text {
            visible: btn.label !== ""
            text: btn.label
            color: area.containsMouse ? Theme.darkText : Theme.text
            font { family: Theme.font; pixelSize: 13; bold: true }
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
