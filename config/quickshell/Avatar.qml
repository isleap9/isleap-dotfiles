pragma Singleton

import QtQuick
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io

// Your profile picture: ~/.face (also copied to ~/.face.icon, which KDE apps and login screens read).
// pick() opens the KDE file dialog; the dashboard closes while it's open and comes back after.
Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.face"
    property bool exists: false
    property int version: 0          // bumped on change, so the image reloads
    readonly property string source: exists ? `file://${path}?v=${version}` : ""

    function pick() {
        Globals.dashboardOpen = false;
        dialog.open();
    }
    function remove() {
        save.command = ["sh", "-c", 'rm -f "$HOME/.face" "$HOME/.face.icon"'];
        save.running = true;
    }

    FileDialog {
        id: dialog
        title: "Choose a profile picture"
        currentFolder: "file://" + Quickshell.env("HOME") + "/Pictures"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.bmp *.gif)"]
        onAccepted: {
            const file = decodeURIComponent(String(selectedFile).replace(/^file:\/\//, ""));
            save.command = ["sh", "-c", 'cp -f -- "$1" "$HOME/.face" && cp -f "$HOME/.face" "$HOME/.face.icon"', "sh", file];
            save.running = true;
        }
        onRejected: Globals.toggleDashboard("overview", null)
    }

    Process {
        id: save
        onExited: {
            check.running = true;
            Globals.toggleDashboard("overview", null);
        }
    }

    Process {
        id: check
        running: true
        command: ["sh", "-c", 'test -f "$HOME/.face" && echo yes']
        stdout: StdioCollector {
            onStreamFinished: {
                root.exists = text.trim() === "yes";
                root.version++;
            }
        }
    }
}
