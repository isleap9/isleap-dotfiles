//@ pragma UseQApplication
//@ pragma IconTheme breeze-dark

import QtQuick
import Quickshell
import qs.bar
import qs.launcher
import qs.notifications
import qs.powermenu
import qs.controlcenter
import qs.settings
import qs.dashboard
import qs.osd
import qs.quicksettings
import qs.overview
import qs.polkit
import qs.desktop

ShellRoot {
    // A bar on every monitor
    Variants {
        model: Quickshell.screens

        Bar {}
    }

    NotificationPopups {}
    NotificationCenter {}
    Launcher {}
    PowerMenu {}
    ControlCenter {}
    SettingsWindow {}
    Dashboard {}
    Osd {}
    QuickSettings {}
    Overview {}
    PolkitDialog {}
    TrayMenu {}
    DesktopWidgets {}
}
