import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components

// 12h clock; click for the long date, hover for a calendar (scroll to change month)
Pill {
    id: root

    shown: Config.bar.modules.clock
    property string format: Config.bar.clock24h ? "HH:mm" : "hh:mm AP"
    property string longFormat: "dddd, MMMM dd, yyyy (HH:mm)"
    property bool showCalendar: true
    property alias textItem: label
    property bool long: false

    onClicked: if (longFormat !== "") long = !long

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    BarText {
        id: label
        // "hh12" = 12-hour hour on its own (Qt only uses 12h when AP is in the same format)
        text: root.long ? Qt.formatDateTime(clock.date, root.longFormat)
            : root.format === "hh12" ? Qt.formatDateTime(clock.date, "hh AP").split(" ")[0]
            : Qt.formatDateTime(clock.date, root.format)
    }

    Tooltip {
        target: root
        show: root.hovered && root.showCalendar

        Calendar {}
    }
}
