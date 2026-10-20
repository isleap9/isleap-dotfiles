import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

// Month calendar (weeks start on Monday). Arrows or scroll to change month; click the title for today.
DashCard {
    id: card

    property int offset: 0
    SystemClock { id: clock; precision: SystemClock.Hours }
    readonly property date today: clock.date
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + offset, 1)
    readonly property int firstDay: (shown.getDay() + 6) % 7
    readonly property int daysInMonth: new Date(shown.getFullYear(), shown.getMonth() + 1, 0).getDate()
    readonly property int prevDays: new Date(shown.getFullYear(), shown.getMonth(), 0).getDate()
    readonly property int weeks: Math.ceil((firstDay + daysInMonth) / 7)

    WheelHandler { onWheel: e => card.offset += e.angleDelta.y > 0 ? -1 : 1 }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: Qt.formatDate(card.shown, "MMMM yyyy")
                color: Theme.fg1
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 1
                font.weight: Font.Bold
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: card.offset = 0 }
            }
            DashButton { icon: "\u{F0141}"; size: 30; onClicked: card.offset-- }
            DashButton { icon: "\u{F0142}"; size: 30; onClicked: card.offset++ }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            rowSpacing: 0
            columnSpacing: 0

            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                Text {
                    required property string modelData
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Theme.fg2
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 3
                    font.weight: Font.Bold
                }
            }

            Repeater {
                model: card.weeks * 7

                Item {
                    id: cell
                    required property int index
                    readonly property int day: index - card.firstDay + 1
                    readonly property bool inMonth: day >= 1 && day <= card.daysInMonth
                    readonly property bool isToday: inMonth && card.offset === 0 && day === card.today.getDate()
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) - 2
                        height: width
                        radius: width / 2
                        color: cell.isToday ? Theme.accent : "transparent"
                    }
                    Text {
                        anchors.centerIn: parent
                        text: cell.inMonth ? cell.day : cell.day < 1 ? card.prevDays + cell.day : cell.day - card.daysInMonth
                        color: cell.isToday ? Theme.bg0 : cell.inMonth ? (cell.index % 7 >= 5 ? Theme.fg2 : Theme.fg1) : Theme.bg4
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 2
                        font.weight: cell.isToday ? Font.Black : Font.Bold
                    }
                }
            }
        }
    }
}
