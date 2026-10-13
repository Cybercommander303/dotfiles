import QtQuick

// Translucent charcoal panel: thin cyan border, top sheen, faint outer halo.
Item {
    id: g
    property real radius: 16
    property real glass: 0.66
    property real borderAlpha: 0.22
    default property alias content: inner.data

    Rectangle {
        anchors.fill: parent; anchors.margins: -4
        radius: g.radius + 4; color: "transparent"
        border.width: 1; border.color: Config.alpha(Config.cyan, 0.05)
    }
    Rectangle {
        anchors.fill: parent; anchors.margins: -8
        radius: g.radius + 8; color: "transparent"
        border.width: 1; border.color: Config.alpha(Config.cyan, 0.025)
    }
    Rectangle {
        anchors.fill: parent
        radius: g.radius
        color: Config.alpha(Config.charcoal, g.glass)
        border.width: 1
        border.color: Config.alpha(Config.cyan, g.borderAlpha)
    }
    Rectangle {   // top sheen
        anchors.fill: parent; anchors.margins: 1
        radius: g.radius - 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.11) }
            GradientStop { position: 0.38; color: Qt.rgba(1, 1, 1, 0.0) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
        }
    }
    Item { id: inner; anchors.fill: parent }
}
