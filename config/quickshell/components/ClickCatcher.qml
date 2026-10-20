import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// Click outside to close (like Caelestia): while any panel is open, an invisible layer covers
// every monitor just under the panels (but not the bar, so bar buttons keep working).
// A click on it closes whatever is open.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property ShellScreen modelData
        screen: modelData

        readonly property bool anyOpen: Globals.launcherOpen || Globals.notifCenterOpen
            || Globals.controlCenterOpen || Globals.dashboardOpen || Globals.quickSettingsOpen
            || Globals.trayMenuItem !== null || Globals.overviewOpen || Globals.powerMenuOpen
        // Safety: if something refuses to close, stop catching clicks anyway so the
        // desktop never gets stuck under an invisible layer
        property bool suppressed: false
        onAnyOpenChanged: suppressed = false

        visible: anyOpen && !suppressed
        anchors { top: true; bottom: true; left: true; right: true }
        // Stays out of the bar's reserved area
        exclusionMode: ExclusionMode.Normal
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-clickcatcher"

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: {
                Globals.closeAll();
                Globals.overviewOpen = false;
                if (win.anyOpen) win.suppressed = true;
            }
        }
    }
}
