pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// All user settings, saved to ~/.config/quickshell/config.json.
// Edited by the Settings app; anything missing from the file uses the defaults below.
Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.config/quickshell/config.json"

    property alias appearance: adapter.appearance
    property alias bar: adapter.bar
    property alias notifications: adapter.notifications
    property alias launcher: adapter.launcher
    property alias powerMenu: adapter.powerMenu

    // Put every setting back to its default
    function reset() {
        file.setText("{}\n");
        file.reload();
    }

    FileView {
        id: file
        path: root.path
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) writeAdapter();
        }

        JsonAdapter {
            id: adapter

            property JsonObject appearance: JsonObject {
                property string font: "Google Sans Display"
                property string iconFont: "JetBrainsMono Nerd Font Propo"
                property int fontSize: 15
                property real animationSpeed: 1.0   // 0 = off, 0.5 = fast, 1 = normal, 2 = slow
            }

            property JsonObject bar: JsonObject {
                property int height: 40
                property int topMargin: 16
                property int sideMargin: 30
                property int spacing: 18
                property bool clock24h: false
                property string weatherCity: "Bari"
                property int minWorkspaces: 4
                property JsonObject modules: JsonObject {
                    property bool weather: true
                    property bool clock: true
                    property bool cava: true
                    property bool media: true
                    property bool tray: true
                    property bool language: true
                    property bool volume: true
                    property bool network: true
                    property bool notifications: true
                    property bool power: true
                }
            }

            property JsonObject notifications: JsonObject {
                property int timeout: 5          // seconds a popup stays up
                property string position: "top-right"   // top-right, top-left, bottom-right, bottom-left
                property int maxPopups: 4
            }

            property JsonObject launcher: JsonObject {
                property int width: 620
                property int height: 520
                property bool showDescriptions: true
            }

            property JsonObject powerMenu: JsonObject {
                property bool confirm: true
            }
        }
    }
}
