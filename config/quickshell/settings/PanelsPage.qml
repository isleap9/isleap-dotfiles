import QtQuick
import QtQuick.Layouts
import qs
import qs.components

// Icons, panels (dashboard, quick settings, menus), hover cards, on-screen popups
Page {
    Section {
        title: "Icons"
        description: "Material Symbols (Rounded), used everywhere in the shell"
        Option {
            label: "Always filled"
            description: Config.icons.filled ? "Icons are always solid" : "Outlined, filling in smoothly on hover and when something is on (Material 3)"
            MSwitch { checked: Config.icons.filled; onToggled: Config.icons.filled = !checked }
        }
        Option {
            label: "Icon weight"
            description: "Stroke thickness"
            Segmented {
                options: [[300, "Light"], [400, "Regular"], [500, "Medium"], [600, "Bold"]]
                current: Config.icons.weight
                onSelected: v => Config.icons.weight = v
            }
        }
    }

    Section {
        title: "Panels"
        description: "Dashboard, quick settings and tray menus"
        Option {
            label: "Corner roundness"
            Stepper { value: Config.panels.radius; from: 8; to: 40; step: 2; suffix: " px"; onChanged: v => Config.panels.radius = v }
        }
        Option {
            label: "Joint with the bar"
            description: "Size of the curve where a panel meets a one-piece bar"
            Stepper { value: Config.panels.joint; from: 8; to: 40; step: 2; suffix: " px"; onChanged: v => Config.panels.joint = v }
        }
    }

    Section {
        title: "Dashboard"
        Option {
            label: "SUPER+A opens"
            Segmented {
                options: [["last", "Last tab"], ["overview", "Overview"], ["media", "Media"], ["weather", "Weather"], ["wallpaper", "Wallpapers"]]
                current: Config.dashboard.openOn
                onSelected: v => Config.dashboard.openOn = v
            }
        }
        Option {
            label: "Units"
            Segmented {
                options: [["metric", "°C, km/h"], ["imperial", "°F, mph"]]
                current: Config.dashboard.units
                onSelected: v => Config.dashboard.units = v
            }
        }
        Option {
            label: "Overview cards"
            description: "Arrange them with Edit in the dashboard"
            PillButton { text: "Reset to default"; onClicked: Config.dashboard.cards = [] }
        }
    }

    Section {
        title: "Hover cards"
        description: "Calendar on the clock, forecast on the weather, names in the taskbar"
        Option {
            label: "Show hover cards"
            MSwitch { checked: Config.panels.hoverCards; onToggled: Config.panels.hoverCards = !checked }
        }
        Option {
            visible: Config.panels.hoverCards
            label: "Delay"
            Stepper { value: Config.panels.hoverDelay; from: 0; to: 1500; step: 50; suffix: " ms"; onChanged: v => Config.panels.hoverDelay = v }
        }
    }

    Section {
        title: "On-screen popups"
        Option {
            label: "Show popups"
            MSwitch { checked: Config.osd.enabled; onToggled: Config.osd.enabled = !checked }
        }
        Option {
            visible: Config.osd.enabled
            label: "Position"
            Segmented {
                options: [["top", "Top"], ["center", "Center"], ["bottom", "Bottom"]]
                current: Config.osd.position
                onSelected: v => Config.osd.position = v
            }
        }
        Option {
            visible: Config.osd.enabled
            label: "Stays for"
            Stepper { value: Config.osd.duration; from: 500; to: 5000; step: 100; suffix: " ms"; onChanged: v => Config.osd.duration = v }
        }
        Option { visible: Config.osd.enabled; label: "Volume"; MSwitch { checked: Config.osd.volume; onToggled: Config.osd.volume = !checked } }
        Option { visible: Config.osd.enabled; label: "Microphone mute"; MSwitch { checked: Config.osd.mic; onToggled: Config.osd.mic = !checked } }
        Option { visible: Config.osd.enabled; label: "Caps Lock"; MSwitch { checked: Config.osd.caps; onToggled: Config.osd.caps = !checked } }
        Option { visible: Config.osd.enabled; label: "Keyboard layout"; MSwitch { checked: Config.osd.layout; onToggled: Config.osd.layout = !checked } }
    }

    Section {
        title: "Keep awake"
        Option {
            label: "Keep the screen on"
            description: "No dimming, locking, screen-off or suspend while on"
            MSwitch { checked: Globals.keepAwake; onToggled: Globals.setKeepAwake(!checked) }
        }
    }
}
