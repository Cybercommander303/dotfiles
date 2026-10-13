import QtQuick

Row {
    id: root
    property bool mirrored: false             // true = bass on the right (for the left-hand visualizer)
    property real maxHeight: 22
    spacing: 3
    height: maxHeight

    Repeater {
        model: Cava.bars

        Rectangle {
            required property int index
            readonly property real level: Cava.values[root.mirrored ? Cava.bars - 1 - index : index] / 100

            width: 3
            height: Math.max(3, level * root.maxHeight)
            y: (root.maxHeight - height) / 2   // grow up and down from the middle
            radius: width / 2
            color: Theme.cava

            Behavior on height { NumberAnimation { duration: 70; easing.type: Easing.OutQuad } }
        }
    }
}
