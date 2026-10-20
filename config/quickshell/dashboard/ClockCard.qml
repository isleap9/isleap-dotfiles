import QtQuick
import Quickshell
import qs

// Big digital clock with the date
DashCard {
    id: card

    readonly property bool h24: Config.bar.clock24h
    readonly property bool tall: height >= 200

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: card.tall ? 6 : 0

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            Text {
                id: time
                text: Qt.formatTime(clock.date, card.h24 ? "HH:mm" : "hh:mm AP").split(" ")[0]
                color: Theme.accent
                font.family: Theme.font
                font.pixelSize: Math.min(card.height * (card.tall ? 0.36 : 0.5), card.width * 0.26)
                font.weight: Font.Bold
                font.features: ({ tnum: 1 })
            }
            Text {
                visible: !card.h24
                anchors.baseline: time.baseline
                text: Qt.formatTime(clock.date, "AP")
                color: Theme.fg2
                font.family: Theme.font
                font.pixelSize: Math.max(12, time.font.pixelSize * 0.28)
                font.weight: Font.Bold
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(clock.date, card.width < 200 ? "ddd d" : "dddd, MMMM d")
            color: Theme.fg2
            font.family: Theme.font
            font.pixelSize: card.tall ? Theme.fontSize + 2 : Theme.fontSize - 2
            font.weight: Font.Bold
        }
    }
}
