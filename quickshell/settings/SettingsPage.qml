import QtQuick

// One settings section: heading, staggered rows (children), Cancel / Apply / OK row.
Item {
    id: page
    property string title: ""
    property string subtitle: ""
    property int index: 0
    property int current: 0
    readonly property bool active: index === current
    default property alias content: col.data
    signal closeRequested()

    property real reveal: active ? 1 : 0
    // leaving pages vanish fast (90 ms); the incoming page waits ~90 ms before
    // its rows start, so the two pages are never visible at the same time
    Behavior on reveal { NumberAnimation { duration: page.active ? 750 : 90; easing.type: Easing.Linear } }

    opacity: Math.max(0, Math.min(1, reveal * 4))
    visible: opacity > 0.01
    enabled: active

    // rows fade/slide in one after another whenever the page becomes active
    Component.onCompleted: {
        for (var i = 0; i < col.children.length; i++) {
            (function (item, idx) {
                var t = function () { return Math.max(0, Math.min(1, page.reveal * 5 - 0.1 - idx * 0.5)); };
                item.opacity = Qt.binding(t);
                item.x = Qt.binding(function () { return (1 - t()) * 34; });
            })(col.children[i], i);
        }
    }

    Text {
        id: head
        text: page.title
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fsTitle
        font.weight: Font.Bold
    }
    Text {
        y: head.height + 2
        text: page.subtitle
        color: Theme.sub
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fsSmall
    }
    Rectangle {   // accent underline that draws itself
        y: head.height + 22
        height: 3
        radius: 1.5
        width: 56 * Math.min(1, page.reveal * 2)
        color: Theme.accent
    }

    Column {
        id: col
        y: 74
        width: parent.width
        spacing: 4
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 68
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.border }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        spacing: 14

        AnimButton {
            text: "Cancel"; icon: "cross"; tint: Theme.danger; delay: 380
            onClicked: { HyprSettings.revert(); page.closeRequested(); }
        }
        AnimButton {
            text: "Apply"; icon: "apply"; tint: Theme.accent2
            onClicked: HyprSettings.apply()
        }
        AnimButton {
            text: "OK"; icon: "check"; tint: Theme.ok; delay: 380
            onClicked: { HyprSettings.apply(); page.closeRequested(); }
        }
    }
}
