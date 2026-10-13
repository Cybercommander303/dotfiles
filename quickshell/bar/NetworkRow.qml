import QtQuick
import QtQuick.Layouts

Item {
    id: row
    required property var net          // { ssid, signal, secure, active, saved }
    property bool expanded: false
    property bool askPassword: false
    signal toggled()

    readonly property bool busy: Wifi.busySsid === net.ssid

    width: ListView.view ? ListView.view.width : 300
    height: 46 + (expanded ? body.implicitHeight + 12 : 0)
    clip: true
    Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

    onExpandedChanged: if (!expanded) { askPassword = false; pwd.text = "" }

    function proceed() {
        // open or already-known networks connect straight away; new secured ones need a password
        if (net.secure && !net.saved && !net.active) {
            askPassword = true
            Qt.callLater(() => pwd.forceActiveFocus())
        } else {
            Wifi.connect(net.ssid, "")
        }
    }
    function submit() { if (pwd.text.length > 0) Wifi.connect(net.ssid, pwd.text) }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: head.containsMouse || row.expanded ? Theme.surface : "transparent"
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    MouseArea {
        id: head
        width: parent.width
        height: 46
        hoverEnabled: true
        cursorShape: row.net.active ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: if (!row.net.active) row.toggled()

        RowLayout {
            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
            spacing: 12

            Text {
                text: "\uf1eb"
                color: head.containsMouse ? Theme.globe : Theme.accent
                opacity: 0.35 + row.net.signal / 100 * 0.65
                font { family: Theme.iconFont; pixelSize: 15 }
                scale: head.containsMouse ? 1.2 : 1
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }
            Text {
                Layout.fillWidth: true
                text: row.net.ssid
                elide: Text.ElideRight
                color: row.net.active ? Theme.globe : Theme.text
                font { family: Theme.font; pixelSize: 13; bold: row.net.active }
            }
            Text {
                visible: row.net.secure
                text: "\uf023"
                color: Theme.muted
                font { family: Theme.iconFont; pixelSize: 12 }
            }
            Text {
                visible: row.net.active
                text: "\uf00c"
                color: Theme.globe
                font { family: Theme.iconFont; pixelSize: 13 }
            }
        }
    }

    Column {
        id: body
        x: 14
        y: 48
        width: parent.width - 28
        spacing: 8

        HoverButton {
            visible: !row.busy && !row.askPassword
            icon: "\uf0c1"
            label: "Connect"
            onClicked: row.proceed()
        }

        Row {
            visible: row.busy
            spacing: 8
            Text {
                text: "\uf110"
                color: Theme.globe
                font { family: Theme.iconFont; pixelSize: 14 }
                RotationAnimator on rotation { from: 0; to: 360; duration: 900; loops: Animation.Infinite; running: row.busy }
            }
            Text {
                text: "Connecting…"
                color: Theme.muted
                font { family: Theme.font; pixelSize: 13 }
            }
        }

        Rectangle {
            visible: row.askPassword && !row.busy
            width: parent.width
            height: 38
            radius: 10
            color: Theme.surface
            border.width: 1
            border.color: pwd.activeFocus ? Theme.globe : Theme.border
            Behavior on border.color { ColorAnimation { duration: 200 } }

            RowLayout {
                anchors { fill: parent; leftMargin: 12; rightMargin: 4 }
                spacing: 8

                TextInput {
                    id: pwd
                    Layout.fillWidth: true
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: Theme.text
                    selectByMouse: true
                    clip: true
                    font { family: Theme.font; pixelSize: 13 }
                    onAccepted: row.submit()

                    Text {
                        visible: pwd.text.length === 0
                        text: "Password"
                        color: Theme.muted
                        font: pwd.font
                    }
                }
                HoverButton {
                    icon: "\uf061"
                    implicitHeight: 30
                    onClicked: row.submit()
                }
            }
        }
    }
}
