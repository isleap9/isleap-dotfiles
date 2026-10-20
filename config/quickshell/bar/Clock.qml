import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components

// Clock. Options (Settings → Bar → Clock ⚙): what it shows, calendar on hover, big text.
// Click: the dashboard. Right click: the full date. Hover: a calendar (scroll it to change month).
Pill {
    id: root

    readonly property string mode: BarConfig.opt(settings, "format")
    readonly property bool h24: Config.bar.clock24h
    readonly property bool showCalendar: BarConfig.opt(settings, "calendar")
    property bool long: false
    property var screen: null

    onClicked: m => {
        if (m.button === Qt.RightButton) long = !long;
        else Globals.toggleDashboard("overview", screen);
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    function text(date) {
        if (long) return Qt.formatDateTime(date, h24 ? "dddd, MMMM dd, yyyy (HH:mm)" : "dddd, MMMM dd, yyyy (hh:mm AP)");
        switch (mode) {
        case "date": return Qt.formatDateTime(date, h24 ? "ddd dd MMM  HH:mm" : "ddd dd MMM  hh:mm AP");
        // Qt only uses 12-hour time when AP is in the same format, so cut the AM/PM off afterwards
        case "hour": return h24 ? Qt.formatDateTime(date, "HH") : Qt.formatDateTime(date, "hh AP").split(" ")[0];
        case "minutes": return Qt.formatDateTime(date, h24 ? "mm" : "mm AP");
        default: return Qt.formatDateTime(date, h24 ? "HH:mm" : "hh:mm AP");
        }
    }

    BarText {
        text: root.text(clock.date)
        font.pixelSize: BarConfig.opt(root.settings, "large") ? BarConfig.textSize + 3 : BarConfig.textSize
        font.weight: BarConfig.opt(root.settings, "large") ? Font.Bold : BarConfig.textWeight
    }

    Tooltip {
        target: root
        show: (root.hovered || Globals.hoverPreview === "clock") && root.showCalendar && !Globals.dashboardOpen

        Calendar {}
    }
}
