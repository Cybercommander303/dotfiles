import Quickshell
import QtQuick

Text {
    SystemClock { id: clock; precision: SystemClock.Minutes }

    text: Qt.formatDateTime(clock.date, "ddd d MMM  ·  hh:mm")
    color: Theme.text
    font { family: Theme.font; pixelSize: Theme.fontSize; bold: true }
}
