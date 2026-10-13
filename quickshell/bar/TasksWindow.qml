import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        readonly property string ui: "Montserrat"
        readonly property bool here: !Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === modelData.name
        visible: here && (TaskState.open || card.opacity > 0.01)

        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "mybar-tasks"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: TaskState.open && here ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        function submit() {
            if (input.text.trim() === "") { shake.restart(); return }
            TaskState.add(input.text)
            input.text = ""
        }

        Connections {
            target: TaskState
            function onOpenChanged() {
                if (TaskState.open) { input.text = ""; focusTimer.restart() }
            }
        }
        Timer { id: focusTimer; interval: 60; onTriggered: input.forceActiveFocus() }

        MouseArea { anchors.fill: parent; onClicked: TaskState.open = false }

        TiltCard {
            id: card
            shown: TaskState.open
            width: 440
            height: 520

            // ---------- pencil that keeps writing a line ----------
            Item {
                id: pencil
                width: 100
                height: 56
                anchors { top: parent.top; topMargin: 16; horizontalCenter: parent.horizontalCenter }

                property real p: 0           // how far the line is drawn (0..1)
                property real fade: 1
                opacity: card.shown ? 1 : 0
                scale: card.shown ? 1 : 0.4
                Behavior on opacity { NumberAnimation { duration: 450 } }
                Behavior on scale   { NumberAnimation { duration: 600; easing.type: Easing.OutBack } }

                SequentialAnimation {
                    running: card.shown
                    loops: Animation.Infinite
                    NumberAnimation { target: pencil; property: "p"; from: 0; to: 1; duration: input.text.length > 0 ? 650 : 1200; easing.type: Easing.InOutSine }
                    NumberAnimation { target: pencil; property: "fade"; from: 1; to: 0; duration: 350 }
                    ScriptAction { script: { pencil.p = 0; pencil.fade = 1 } }
                    PauseAnimation { duration: 120 }
                }

                Rectangle {                                   // the stroke
                    x: 14
                    y: 46
                    width: 72 * pencil.p
                    height: 3
                    radius: 1.5
                    color: Theme.accent
                    opacity: pencil.fade
                }
                Text {                                        // the pencil, its tip rides the end of the stroke
                    id: pen
                    text: "\uf040"
                    color: Theme.accent
                    font { family: Theme.iconFont; pixelSize: 30 }
                    x: 10 + 72 * pencil.p
                    y: 46 - implicitHeight + 4 + 2.5 * Math.sin(pencil.p * 38)
                    rotation: 3 * Math.sin(pencil.p * 30)
                    transformOrigin: Item.BottomLeft
                }
            }

            Text {
                id: title
                anchors { top: pencil.bottom; topMargin: 4; horizontalCenter: parent.horizontalCenter }
                text: "Tasks"
                color: Theme.text
                font { family: win.ui; pixelSize: 18; weight: Font.DemiBold }
            }
            Text {
                id: subtitle
                anchors { top: title.bottom; topMargin: 2; horizontalCenter: parent.horizontalCenter }
                text: TaskState.items.count === 0 ? "nothing yet" : (TaskState.pending === 0 ? "all done" : TaskState.pending + " to do")
                color: TaskState.pending > 0 ? Theme.bulb : Theme.muted
                font { family: win.ui; pixelSize: 11 }
                Behavior on color { ColorAnimation { duration: 250 } }
            }

            // ---------- add-a-task field ----------
            Rectangle {
                id: field
                anchors { top: subtitle.bottom; topMargin: 16; left: parent.left; right: parent.right; leftMargin: 22; rightMargin: 22 }
                height: 46
                radius: 13
                color: Theme.surface
                border.width: 1
                border.color: input.activeFocus ? Theme.accent : Theme.border
                Behavior on border.color { ColorAnimation { duration: 200 } }
                transform: Translate { id: shiftX }

                // every keystroke: a glow ripple and a tiny bounce
                Rectangle {
                    id: glow
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.accent
                    opacity: 0
                }
                ParallelAnimation {
                    id: keystroke
                    NumberAnimation { target: glow; property: "opacity"; from: 0.7; to: 0; duration: 380; easing.type: Easing.OutCubic }
                    SequentialAnimation {
                        NumberAnimation { target: field; property: "scale"; to: 1.012; duration: 70 }
                        NumberAnimation { target: field; property: "scale"; to: 1; duration: 220; easing.type: Easing.OutBack }
                    }
                }
                // empty submit: shake
                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: shiftX; property: "x"; to: -8; duration: 50 }
                    NumberAnimation { target: shiftX; property: "x"; to: 8; duration: 70 }
                    NumberAnimation { target: shiftX; property: "x"; to: -5; duration: 60 }
                    NumberAnimation { target: shiftX; property: "x"; to: 0; duration: 60 }
                }

                // underline that fills as you type
                Rectangle {
                    anchors { left: parent.left; bottom: parent.bottom; leftMargin: 16; bottomMargin: 1 }
                    height: 2
                    radius: 1
                    color: Theme.accent
                    width: (parent.width - 32) * Math.min(1, input.text.length / 60)
                    Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                }

                RowLayout {
                    anchors { fill: parent; leftMargin: 16; rightMargin: 7 }
                    spacing: 10

                    TextInput {
                        id: input
                        Layout.fillWidth: true
                        color: Theme.text
                        selectByMouse: true
                        clip: true
                        maximumLength: 120
                        font { family: win.ui; pixelSize: 14 }
                        onTextChanged: keystroke.restart()
                        Keys.onReturnPressed: win.submit()
                        Keys.onEnterPressed: win.submit()
                        Keys.onEscapePressed: TaskState.open = false

                        // caret that glides between letters and blinks
                        cursorDelegate: Rectangle {
                            width: 2
                            radius: 1
                            color: Theme.accent
                            Behavior on x { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.1; duration: 520 }
                                NumberAnimation { to: 1; duration: 520 }
                            }
                        }

                        Text {
                            visible: input.text.length === 0
                            text: "What needs doing?"
                            color: Theme.muted
                            font: input.font
                        }
                    }

                    Rectangle {                                       // add button
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 10
                        color: addHit.containsMouse ? Theme.accent : "transparent"
                        border.width: 1
                        border.color: Theme.accent
                        scale: addHit.pressed ? 0.92 : (addHit.containsMouse ? 1.08 : 1)
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        Text {
                            anchors.centerIn: parent
                            text: "\uf067"
                            color: addHit.containsMouse ? Theme.darkText : Theme.accent
                            font { family: Theme.iconFont; pixelSize: 13 }
                            rotation: addHit.containsMouse ? 90 : 0
                            Behavior on rotation { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }
                        MouseArea {
                            id: addHit
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.submit()
                        }
                    }
                }
            }

            // ---------- the list ----------
            ListView {
                id: list
                anchors { top: field.bottom; topMargin: 14; left: parent.left; right: parent.right; bottom: footer.top; leftMargin: 22; rightMargin: 22; bottomMargin: 4 }
                clip: true
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds
                model: TaskState.items

                add: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 300 }
                        NumberAnimation { property: "scale"; from: 0.85; to: 1; duration: 340; easing.type: Easing.OutBack }
                    }
                }
                remove: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; to: 0; duration: 220 }
                        NumberAnimation { property: "scale"; to: 0.8; duration: 220 }
                    }
                }
                displaced: Transition { NumberAnimation { properties: "y"; duration: 280; easing.type: Easing.OutCubic } }
                move: Transition { NumberAnimation { properties: "y"; duration: 320; easing.type: Easing.OutCubic } }

                delegate: Item {
                    id: row
                    required property int index
                    required property string title
                    required property bool done
                    readonly property bool hovered: rowHover.containsMouse

                    width: ListView.view.width
                    height: 42

                    Rectangle {
                        anchors.fill: parent
                        radius: 11
                        color: row.hovered ? Theme.surface : "transparent"
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }

                    Item {                                            // content nudges right on hover
                        width: parent.width
                        height: parent.height
                        x: row.hovered ? 4 : 0
                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            spacing: 12

                            Rectangle {                               // checkbox
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                radius: 10
                                color: row.done ? Theme.accent : "transparent"
                                border.width: 2
                                border.color: row.done || boxHit.containsMouse ? Theme.accent : Theme.muted
                                scale: boxHit.containsMouse ? 1.15 : 1
                                Behavior on color        { ColorAnimation { duration: 180 } }
                                Behavior on border.color { ColorAnimation { duration: 180 } }
                                Behavior on scale        { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf00c"
                                    color: Theme.darkText
                                    font { family: Theme.iconFont; pixelSize: 10 }
                                    scale: row.done ? 1 : 0
                                    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }
                                }
                                MouseArea {
                                    id: boxHit
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: TaskState.toggle(row.index)
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: row.title
                                elide: Text.ElideRight
                                color: row.done ? Theme.muted : Theme.text
                                font { family: win.ui; pixelSize: 13; strikeout: row.done }
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }

                            Text {                                    // delete, fades in on hover
                                text: "\uf00d"
                                color: delHit.containsMouse ? Theme.red : Theme.muted
                                font { family: Theme.iconFont; pixelSize: 13 }
                                opacity: row.hovered ? 1 : 0
                                scale: delHit.containsMouse ? 1.25 : 1
                                Behavior on opacity { NumberAnimation { duration: 160 } }
                                Behavior on scale   { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                                Behavior on color   { ColorAnimation { duration: 140 } }
                                MouseArea {
                                    id: delHit
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: TaskState.remove(row.index)
                                }
                            }
                        }
                    }

                    // row-wide hover detector (on top, lets clicks through)
                    MouseArea {
                        id: rowHover
                        anchors.fill: parent
                        z: 10
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    text: "All clear.\nAdd something above."
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.muted
                    font { family: win.ui; pixelSize: 12 }
                }
            }

            Item {
                id: footer
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 22; rightMargin: 22 }
                height: 36

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "↵ add     ○ done     esc close"
                    color: Theme.muted
                    font { family: win.ui; pixelSize: 10 }
                }

                // removes every finished task at once; only shows when there are some
                Rectangle {
                    id: clearBtn
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    width: clearRow.implicitWidth + 22
                    height: 26
                    radius: 9
                    color: clearHit.containsMouse ? Theme.red : "transparent"
                    border.width: 1
                    border.color: Theme.red
                    opacity: TaskState.doneCount > 0 ? 1 : 0
                    scale: clearHit.pressed ? 0.94 : (clearHit.containsMouse ? 1.06 : 1)
                    Behavior on opacity { NumberAnimation { duration: 220 } }
                    Behavior on color   { ColorAnimation { duration: 180 } }
                    Behavior on scale   { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    RowLayout {
                        id: clearRow
                        anchors.centerIn: parent
                        spacing: 7
                        Text {
                            text: "\uf1f8"
                            color: clearHit.containsMouse ? Theme.darkText : Theme.red
                            font { family: Theme.iconFont; pixelSize: 11 }
                            transformOrigin: Item.BottomLeft
                            rotation: clearHit.containsMouse ? -14 : 0
                            Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }
                        Text {
                            text: "Clear done"
                            color: clearHit.containsMouse ? Theme.darkText : Theme.red
                            font { family: win.ui; pixelSize: 10; weight: Font.DemiBold }
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }
                    }
                    MouseArea {
                        id: clearHit
                        anchors.fill: parent
                        enabled: TaskState.doneCount > 0
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: TaskState.clearDone()
                    }
                }
            }
        }
    }
}
