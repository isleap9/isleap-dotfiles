import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

Page {
    id: page

    Section {
        title: "Notifications"
        Option {
            icon: "󰂛"
            label: "Do not disturb"
            description: "Hide popups (critical ones still show). Also: right-click the bell on the bar."
            Toggle { checked: Notifs.dnd; onToggled: Notifs.dnd = !Notifs.dnd }
        }
        Option {
            icon: "󰔛"
            label: "Popup duration"
            description: "Unless the app asks for a specific time"
            Stepper { value: Config.notifications.timeout; from: 1; to: 30; suffix: " s"; onChanged: v => Config.notifications.timeout = v }
        }
        Option {
            icon: "󰍜"
            label: "Most popups at once"
            Stepper { value: Config.notifications.maxPopups; from: 1; to: 10; onChanged: v => Config.notifications.maxPopups = v }
        }
        Option {
            icon: "󰹑"
            label: "Popup position"
            Segmented {
                options: [["top-left", "Top left"], ["top-right", "Top right"], ["bottom-left", "Bottom left"], ["bottom-right", "Bottom right"]]
                current: Config.notifications.position
                onSelected: v => Config.notifications.position = v
            }
        }
    }

    Section {
        title: "Try it"
        Option {
            label: "Send a test notification"
            PillButton {
                icon: "󰂚"
                text: "Send"
                onClicked: Quickshell.execDetached(["notify-send", "-a", "Settings", "Test notification",
                    "This is how notifications look right now."])
            }
        }
        Option {
            label: `Clear all notifications (${Notifs.count})`
            PillButton { icon: "󰎟"; text: "Clear"; onClicked: Notifs.clearAll() }
        }
    }
}
