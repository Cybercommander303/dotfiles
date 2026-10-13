import QtQuick

Item {
    id: root
    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Rectangle {                                         // highlight while the panel is open
        anchors.centerIn: parent
        width: icon.implicitWidth + 16
        height: 26
        radius: 9
        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, Notifs.panelOpen ? 0.2 : 0)
        border.width: 1
        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, Notifs.panelOpen ? 0.6 : 0)
        Behavior on color        { ColorAnimation { duration: 220 } }
        Behavior on border.color { ColorAnimation { duration: 220 } }
    }

    Text {
        id: icon
        text: Notifs.dnd ? "\uf1f6" : "\uf0f3"
        color: Notifs.panelOpen || hit.containsMouse ? Theme.accent : (Notifs.dnd ? Theme.muted : Theme.text)
        font { family: Theme.iconFont; pixelSize: 16 }
        transformOrigin: Item.Top
        Behavior on color { ColorAnimation { duration: 200 } }

        // the bar bell rings whenever a new notification arrives
        SequentialAnimation {
            id: ring
            NumberAnimation { target: icon; property: "rotation"; to: -22; duration: 70 }
            NumberAnimation { target: icon; property: "rotation"; to: 18; duration: 110 }
            NumberAnimation { target: icon; property: "rotation"; to: -12; duration: 100 }
            NumberAnimation { target: icon; property: "rotation"; to: 7; duration: 90 }
            NumberAnimation { target: icon; property: "rotation"; to: 0; duration: 80 }
        }
    }
    Connections {
        target: Notifs
        function onHistoryChanged() { if (!Notifs.dnd) ring.restart() }
    }

    Rectangle {                                         // unread count
        x: icon.implicitWidth - 6
        y: -7
        width: Math.max(14, badge.implicitWidth + 8)
        height: 14
        radius: 7
        color: Theme.red
        border.width: 1
        border.color: Theme.bg
        scale: Notifs.history.length > 0 ? 1 : 0
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
        Text {
            id: badge
            anchors.centerIn: parent
            text: Notifs.history.length > 9 ? "9+" : Notifs.history.length
            color: Theme.darkText
            font { family: "Montserrat"; pixelSize: 8; bold: true }
        }
    }

    MouseArea {
        id: hit
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Notifs.panelOpen = !Notifs.panelOpen
    }
}
