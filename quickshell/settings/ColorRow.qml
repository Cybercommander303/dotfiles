import QtQuick

Item {
    id: r
    property string label: ""
    property string key: ""
    readonly property string val: HyprSettings[key]
    readonly property var presets: ["ff6b9d", "7c8cff", "4de1d0", "7cf0a6", "ffd479", "ffffff"]
    readonly property bool hot: rowHover.hovered

    width: parent ? parent.width : 300
    height: 40

    HoverHandler { id: rowHover }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Theme.alpha(Theme.text, r.hot ? 0.045 : 0)
        Behavior on color { ColorAnimation { duration: 160 } }
    }
    Rectangle {
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        radius: 1.5
        height: r.hot ? 20 : 0
        color: Theme.accent
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
    }

    Text {
        x: 14
        width: Theme.labelW - 14
        height: parent.height
        verticalAlignment: Text.AlignVCenter
        text: r.label
        color: r.hot ? Theme.text : Theme.sub
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fs
        Behavior on color { ColorAnimation { duration: 160 } }
    }

    Rectangle {
        id: sw
        x: Theme.labelW
        anchors.verticalCenter: parent.verticalCenter
        width: 26
        height: 26
        radius: 8
        color: "#" + r.val
        border.width: 2
        border.color: Theme.alpha(Theme.text, 0.35)
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    Rectangle {
        id: field
        x: sw.x + 34
        anchors.verticalCenter: parent.verticalCenter
        width: 78
        height: 28
        radius: 8
        color: Theme.panel2
        border.width: 1.5
        border.color: input.activeFocus ? Theme.accent : Theme.border
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Text {
            x: 9
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            text: "#"
            color: Theme.sub
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fs
        }
        TextInput {
            id: input
            x: 21
            width: parent.width - 27
            height: parent.height
            verticalAlignment: TextInput.AlignVCenter
            maximumLength: 6
            selectByMouse: true
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fs
            validator: RegularExpressionValidator { regularExpression: /[0-9a-fA-F]{0,6}/ }
            onTextEdited: if (text.length === 6) HyprSettings[r.key] = text.toLowerCase()
            onActiveFocusChanged: if (!activeFocus) text = r.val
        }
        Binding { target: input; property: "text"; value: r.val; when: !input.activeFocus }
    }

    Row {
        x: field.x + field.width + 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5
        Repeater {
            model: r.presets
            delegate: Rectangle {
                required property string modelData
                width: 15
                height: 15
                radius: 5
                color: "#" + modelData
                border.width: r.val === modelData ? 2 : 0
                border.color: Theme.text
                scale: pma.pressed ? 0.75 : (pma.containsMouse ? 1.4 : 1.0)
                rotation: pma.containsMouse ? 45 : 0
                Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
                Behavior on rotation { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                MouseArea {
                    id: pma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: HyprSettings[r.key] = parent.modelData
                }
            }
        }
    }
}
