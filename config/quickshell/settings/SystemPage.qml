import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs

Page {
    id: page

    property bool confirmReset: false
    property string version: ""

    Section {
        title: "Quickshell"
        Option {
            icon: "sync"
            label: "Restart Quickshell"
            description: "Same as SUPER+R"
            PillButton { text: "Restart"; onClicked: Globals.run("~/.config/quickshell/scripts/launch.sh") }
        }
        Option {
            icon: "folder"
            label: "Config folder"
            description: "~/.config/quickshell"
            PillButton { text: "Open"; onClicked: Quickshell.execDetached(["xdg-open", Quickshell.env("HOME") + "/.config/quickshell"]) }
        }
        Option {
            icon: "data_object"
            label: "Settings file"
            description: "~/.config/quickshell/config.json — everything on these pages is saved here"
            PillButton { text: "Edit"; onClicked: Quickshell.execDetached(["xdg-open", Config.path]) }
        }
        Option {
            icon: "settings_backup_restore"
            label: "Reset all settings"
            description: "Puts every setting on these pages back to default. Doesn't change your theme or wallpaper."
            PillButton {
                text: page.confirmReset ? "Click again to reset" : "Reset"
                danger: page.confirmReset
                onClicked: {
                    if (!page.confirmReset) { page.confirmReset = true; resetTimer.restart(); return; }
                    page.confirmReset = false;
                    Config.reset();
                }
            }
        }
    }

    Section {
        title: "About"
        Option {
            icon: "info"
            label: page.version || "Quickshell"
            description: "Bar, launcher, notifications, power menu, control center and settings — all in ~/.config/quickshell"
        }
    }

    Timer { id: resetTimer; interval: 3000; onTriggered: page.confirmReset = false }

    Process {
        running: true
        command: ["qs", "--version"]
        stdout: StdioCollector { onStreamFinished: page.version = text.trim().split("\n")[0] }
    }
}
