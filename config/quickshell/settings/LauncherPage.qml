import QtQuick
import QtQuick.Layouts
import qs

Page {
    id: page

    Section {
        title: "App launcher"
        description: "Opens with SUPER+SPACE or by clicking the Arch logo"
        Option {
            label: "Width"
            Stepper { value: Config.launcher.width; from: 400; to: 1200; step: 20; suffix: " px"; onChanged: v => Config.launcher.width = v }
        }
        Option {
            label: "Height"
            Stepper { value: Config.launcher.height; from: 300; to: 1000; step: 20; suffix: " px"; onChanged: v => Config.launcher.height = v }
        }
        Option {
            label: "Show app descriptions"
            description: "The small line under each app name"
            Toggle { checked: Config.launcher.showDescriptions; onToggled: Config.launcher.showDescriptions = !checked }
        }
        Option {
            label: "Preview"
            PillButton { icon: "apps"; text: "Open launcher"; onClicked: Globals.launcherOpen = true }
        }
    }

    Section {
        title: "Power menu"
        description: "Opens with SUPER+M or the power button on the bar"
        Option {
            label: "Ask before suspend, logout, reboot and shutdown"
            description: "Lock never asks"
            Toggle { checked: Config.powerMenu.confirm; onToggled: Config.powerMenu.confirm = !checked }
        }
    }
}
