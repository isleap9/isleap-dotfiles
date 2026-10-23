import QtQuick
import QtQuick.Layouts
import qs
import qs.components

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
            label: "Web search"
            description: "Type anything to get a DuckDuckGo row in the results"
            Toggle { checked: Config.launcher.webSearch; onToggled: Config.launcher.webSearch = !checked }
        }
        Option {
            label: "File search"
            description: "Find files and folders in your home folder as you type"
            Toggle { checked: Config.launcher.fileSearch; onToggled: Config.launcher.fileSearch = !checked }
        }
        Option {
            label: "Wallpaper banner"
            description: "Your current wallpaper on top, with the time and a greeting"
            MSwitch { checked: Config.launcher.hero; onToggled: Config.launcher.hero = !checked }
        }
        Option {
            visible: Config.launcher.hero
            label: "Banner height"
            Stepper { value: Config.launcher.heroHeight; from: 100; to: 400; step: 10; suffix: " px"; onChanged: v => Config.launcher.heroHeight = v }
        }
        Option {
            label: "Preview"
            PillButton { icon: "apps"; text: "Open launcher"; onClicked: Globals.launcherOpen = true }
        }
    }

    Section {
        title: "Power menu"
        description: "Opens with SUPER+P or the power button on the bar"
        Option {
            label: "Ask before suspend, logout, reboot and shutdown"
            description: "Lock never asks"
            Toggle { checked: Config.powerMenu.confirm; onToggled: Config.powerMenu.confirm = !checked }
        }
    }
}
