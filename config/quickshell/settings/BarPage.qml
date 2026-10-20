import QtQuick
import QtQuick.Layouts
import qs

Page {
    id: page

    Section {
        title: "Layout"
        Option {
            label: "Bar layout"
            description: ({
                default: "Separate pills, with cava",
                default2: "Grouped right side, classic workspaces",
                minimal: "Everything in one centered pill",
                sleek: "Solid bar attached to the top edge"
            })[BarConfig.layout] ?? ""
            Segmented {
                options: [["default", "Default"], ["default2", "Default 2"], ["minimal", "Minimal"], ["sleek", "Sleek"]]
                current: BarConfig.layout
                onSelected: v => BarConfig.set(v)
            }
        }
    }

    Section {
        title: "Size and spacing"
        Option {
            label: "Height"
            Stepper { value: Config.bar.height; from: 28; to: 60; suffix: " px"; onChanged: v => Config.bar.height = v }
        }
        Option {
            label: "Gap from top of screen"
            description: "Floating layouts only"
            Stepper { value: Config.bar.topMargin; from: 0; to: 40; suffix: " px"; onChanged: v => Config.bar.topMargin = v }
        }
        Option {
            label: "Gap from screen sides"
            Stepper { value: Config.bar.sideMargin; from: 0; to: 120; step: 2; suffix: " px"; onChanged: v => Config.bar.sideMargin = v }
        }
        Option {
            label: "Space between modules"
            Stepper { value: Config.bar.spacing; from: 0; to: 40; step: 2; suffix: " px"; onChanged: v => Config.bar.spacing = v }
        }
    }

    Section {
        title: "Modules"
        description: "Choose what appears on the bar"

        Repeater {
            model: [
                ["weather", "󰖐", "Weather"], ["clock", "󰥔", "Clock"], ["cava", "󰎈", "Audio visualizer (cava)"],
                ["media", "󰝚", "Now playing"], ["tray", "󰀻", "System tray"], ["language", "󰌌", "Keyboard layout"],
                ["volume", "󰕾", "Volume"], ["network", "󰈀", "Network"], ["notifications", "󰂚", "Notifications"],
                ["power", "󰐥", "Power button"]
            ]
            Option {
                id: moduleRow
                required property var modelData
                icon: modelData[1]
                label: modelData[2]
                Toggle {
                    checked: Config.bar.modules[moduleRow.modelData[0]] ?? true
                    onToggled: Config.bar.modules[moduleRow.modelData[0]] = !checked
                }
            }
        }
    }

    Section {
        title: "Clock and weather"
        Option {
            label: "24-hour clock"
            Toggle { checked: Config.bar.clock24h; onToggled: Config.bar.clock24h = !checked }
        }
        Option {
            label: "Weather city"
            description: "Any city name wttr.in understands"
            TextBox { text: Config.bar.weatherCity; placeholder: "e.g. Bari"; onAccepted: v => Config.bar.weatherCity = v.trim() }
        }
    }

    Section {
        title: "Workspaces"
        Option {
            label: "Always show at least"
            description: "Workspaces past this number appear when used"
            Stepper { value: Config.bar.minWorkspaces; from: 1; to: 10; onChanged: v => Config.bar.minWorkspaces = v }
        }
    }
}
