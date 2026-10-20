import QtQuick
import QtQuick.Layouts
import qs

// Month calendar (Material 3), weeks start on Monday. Scroll to move between months.
ColumnLayout {
    id: cal

    property date today: new Date()
    property int offset: 0
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + offset, 1)
    readonly property int firstDay: (shown.getDay() + 6) % 7
    readonly property int daysInMonth: new Date(shown.getFullYear(), shown.getMonth() + 1, 0).getDate()
    readonly property int prevDays: new Date(shown.getFullYear(), shown.getMonth(), 0).getDate()
    readonly property int weeks: Math.ceil((firstDay + daysInMonth) / 7)

    spacing: 6

    WheelHandler { onWheel: e => cal.offset += e.angleDelta.y > 0 ? -1 : 1 }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 6
        Text {
            Layout.fillWidth: true
            text: Qt.formatDate(cal.shown, "MMMM yyyy")
            color: Theme.fg1
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 2
            font.weight: Font.Bold
        }
        Text {
            visible: cal.offset === 0
            text: Qt.formatDate(cal.today, "ddd d")
            color: Theme.accent
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 2
            font.weight: Font.Bold
        }
    }

    GridLayout {
        columns: 7
        rowSpacing: 2
        columnSpacing: 2

        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
            Text {
                required property string modelData
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Theme.fg2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 3
                font.weight: Font.Bold
            }
        }

        Repeater {
            model: cal.weeks * 7

            Rectangle {
                id: d
                required property int index
                readonly property int day: index - cal.firstDay + 1
                readonly property bool inMonth: day >= 1 && day <= cal.daysInMonth
                readonly property bool isToday: inMonth && cal.offset === 0 && day === cal.today.getDate()

                Layout.preferredWidth: 36
                Layout.preferredHeight: 34
                radius: 17
                color: isToday ? Theme.accent : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: d.inMonth ? d.day : d.day < 1 ? cal.prevDays + d.day : d.day - cal.daysInMonth
                    color: d.isToday ? Theme.bg0 : !d.inMonth ? Theme.bg4 : d.index % 7 >= 5 ? Theme.fg2 : Theme.fg1
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                    font.weight: d.isToday ? Font.Black : Font.Bold
                }
            }
        }
    }
}
