import QtQuick
import QtQuick.Layouts
import qs

// Month calendar. Scroll to move between months.
ColumnLayout {
    id: cal

    property date today: new Date()
    property int offset: 0
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + offset, 1)
    // Monday-first index of the 1st of the month
    readonly property int firstDay: (shown.getDay() + 6) % 7
    readonly property int daysInMonth: new Date(shown.getFullYear(), shown.getMonth() + 1, 0).getDate()

    spacing: 6

    WheelHandler {
        onWheel: e => cal.offset += e.angleDelta.y > 0 ? -1 : 1
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDate(cal.shown, "MMMM yyyy")
        color: Theme.accent
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 1
        font.weight: Font.Black
    }

    GridLayout {
        columns: 7
        rowSpacing: 2
        columnSpacing: 2

        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
            Text {
                required property string modelData
                Layout.preferredWidth: 30
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Theme.fg2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                font.weight: Font.Bold
            }
        }

        Repeater {
            model: 42

            Rectangle {
                required property int index
                readonly property int day: index - cal.firstDay + 1
                readonly property bool valid: day >= 1 && day <= cal.daysInMonth
                readonly property bool isToday: valid && cal.offset === 0 && day === cal.today.getDate()

                Layout.preferredWidth: 30
                Layout.preferredHeight: 26
                radius: 13
                color: isToday ? Theme.accent : "transparent"
                visible: index < 35 || cal.firstDay + cal.daysInMonth > 35

                Text {
                    anchors.centerIn: parent
                    text: parent.valid ? parent.day : ""
                    color: parent.isToday ? Theme.bg1 : Theme.fg1
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    font.weight: parent.isToday ? Font.Black : Font.Normal
                }
            }
        }
    }
}
