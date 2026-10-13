import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: card
    property var notif
    property bool hovered: false
    property real slide: 0                       // horizontal offset: used for slide-in and the slingshot
    readonly property bool critical: !!notif && notif.urgency === NotificationUrgency.Critical

    x: slide
    implicitHeight: row.implicitHeight + 28
    radius: 18
    color: hovered ? Qt.lighter(Theme.surface, 1.12) : Theme.surface
    border.width: 1
    border.color: critical ? Theme.red : (hovered ? Theme.accent : Theme.border)
    Behavior on color        { ColorAnimation { duration: 180 } }
    Behavior on border.color { ColorAnimation { duration: 180 } }

    function iconSource() {
        if (!notif) return ""
        if (notif.image && notif.image !== "") return notif.image
        const i = notif.appIcon || ""
        if (i === "") return Quickshell.iconPath("dialog-information")
        return i.startsWith("/") ? "file://" + i : Quickshell.iconPath(i)
    }

    RowLayout {
        id: row
        anchors { fill: parent; margins: 14 }
        spacing: 12

        ClippingRectangle {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 12
            color: Theme.bg
            IconImage { anchors.fill: parent; source: card.iconSource() }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: card.notif ? card.notif.appName : ""
                    elide: Text.ElideRight
                    color: card.critical ? Theme.red : Theme.muted
                    font { family: "Montserrat"; pixelSize: 10; weight: Font.Medium }
                }
                Text {
                    text: Notifs.timeOf(card.notif)
                    color: Theme.muted
                    font { family: "Montserrat"; pixelSize: 10 }
                }
            }
            Text {
                Layout.fillWidth: true
                text: card.notif ? card.notif.summary : ""
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: Theme.text
                font { family: "Montserrat"; pixelSize: 13; weight: Font.DemiBold }
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: card.notif ? card.notif.body : ""
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                color: Theme.muted
                font { family: "Montserrat"; pixelSize: 11 }
            }
        }
    }
}
