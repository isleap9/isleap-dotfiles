import QtQuick
import QtQuick.Layouts
import qs
import qs.components

// Desktop widgets, night light and on-screen popups
Page {
    Section {
        title: "Desktop widgets"
        description: "Drawn on the wallpaper, under your windows"
        Option {
            label: "Show desktop widgets"
            MSwitch { checked: Config.desktop.enabled; onToggled: Config.desktop.enabled = !checked }
        }
        Option {
            visible: Config.desktop.enabled
            label: "Clock"
            MSwitch { checked: Config.desktop.clock; onToggled: Config.desktop.clock = !checked }
        }
        Option {
            visible: Config.desktop.enabled && Config.desktop.clock
            label: "Clock size"
            Stepper { value: Config.desktop.clockSize; from: 48; to: 260; step: 8; suffix: " px"; onChanged: v => Config.desktop.clockSize = v }
        }
        Option {
            visible: Config.desktop.enabled
            label: "Now playing"
            MSwitch { checked: Config.desktop.media; onToggled: Config.desktop.media = !checked }
        }
        Option {
            visible: Config.desktop.enabled
            label: "Weather"
            MSwitch { checked: Config.desktop.weather; onToggled: Config.desktop.weather = !checked }
        }
        Option {
            visible: Config.desktop.enabled
            label: "Position"
            Segmented {
                options: [["top-left", "Top left"], ["top", "Top"], ["center", "Center"], ["bottom-left", "Bottom left"], ["bottom-right", "Bottom right"]]
                current: Config.desktop.position
                onSelected: v => Config.desktop.position = v
            }
        }
        Option {
            visible: Config.desktop.enabled
            label: "Monitors"
            Segmented {
                options: [["main", "Main only"], ["all", "All"]]
                current: Config.desktop.screens
                onSelected: v => Config.desktop.screens = v
            }
        }
    }

    Section {
        title: "Night light"
        description: NightLight.installed ? "Warmer colors to go easy on your eyes" : "Needs hyprsunset: run  sudo pacman -S hyprsunset"
        Option {
            label: "Night light"
            description: NightLight.status
            MSwitch { checked: Config.nightLight.enabled; onToggled: NightLight.toggle() }
        }
        Option {
            label: "Warmth"
            description: "Lower = warmer"
            Stepper { value: Config.nightLight.temperature; from: 2500; to: 6000; step: 250; suffix: " K"; onChanged: v => Config.nightLight.temperature = v }
        }
        Option {
            label: "When"
            Segmented {
                options: [["always", "Always"], ["sun", "Sunset to sunrise"], ["custom", "Custom"]]
                current: Config.nightLight.schedule
                onSelected: v => Config.nightLight.schedule = v
            }
        }
        Option {
            visible: Config.nightLight.schedule === "custom"
            label: "From"
            TextBox { implicitWidth: 120; text: Config.nightLight.from; placeholder: "20:00"; onAccepted: v => Config.nightLight.from = v.trim() }
        }
        Option {
            visible: Config.nightLight.schedule === "custom"
            label: "To"
            TextBox { implicitWidth: 120; text: Config.nightLight.to; placeholder: "07:00"; onAccepted: v => Config.nightLight.to = v.trim() }
        }
    }

    Section {
        title: "On-screen popups"
        Option {
            label: "Volume, microphone, caps lock and layout popups"
            MSwitch { checked: Config.osd.enabled; onToggled: Config.osd.enabled = !checked }
        }
    }
}
