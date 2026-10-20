pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Shared open/closed state for the popups, plus IPC so Hyprland binds can
// toggle them:  qs ipc call launcher toggle
Singleton {
    id: root

    property bool launcherOpen: false
    property bool powerMenuOpen: false
    property bool notifCenterOpen: false
    property bool controlCenterOpen: false
    property string controlCenterPage: "main"
    property bool settingsOpen: false
    property string settingsPage: "appearance"

    // The screen the user is working on (where popups should appear)
    readonly property ShellScreen focusedScreen: {
        const name = Hyprland.focusedMonitor?.name;
        return Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0];
    }

    function closeAll() {
        launcherOpen = false;
        powerMenuOpen = false;
        notifCenterOpen = false;
        controlCenterOpen = false;
    }

    // Open the control center on a page: main, themes, dynamic, clipboard, capture, emoji, cheatsheet
    function openControlCenter(page) {
        const wasOpen = controlCenterOpen && controlCenterPage === page;
        closeAll();
        controlCenterPage = page;
        controlCenterOpen = !wasOpen;
    }

    // Hyprland on this machine uses Lua dispatch syntax
    function dispatch(lua) {
        Hyprland.dispatch(lua);
    }

    function goToWorkspace(id) {
        dispatch(`hl.dsp.focus({ workspace = "${id}" })`);
    }

    function run(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            const open = !root.launcherOpen;
            root.closeAll();
            root.launcherOpen = open;
        }
    }

    IpcHandler {
        target: "powermenu"
        function toggle(): void {
            const open = !root.powerMenuOpen;
            root.closeAll();
            root.powerMenuOpen = open;
        }
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void {
            const open = !root.notifCenterOpen;
            root.closeAll();
            root.notifCenterOpen = open;
        }
        function toggleDnd(): void {
            Notifs.dnd = !Notifs.dnd;
        }
        function clear(): void {
            Notifs.clearAll();
        }
    }

    // Settings is a normal window, so it doesn't close the popups
    function openSettings(page) {
        if (page) settingsPage = page;
        controlCenterOpen = false;
        settingsOpen = true;
    }

    IpcHandler {
        target: "settings"
        function toggle(): void {
            if (root.settingsOpen) root.settingsOpen = false;
            else root.openSettings("");
        }
        // qs ipc call settings open bar
        function open(page: string): void { root.openSettings(page); }
        function launch(): void { root.openSettings(""); }
    }

    IpcHandler {
        target: "controlcenter"
        function toggle(): void {
            root.openControlCenter("main");
        }
        // qs ipc call controlcenter open clipboard
        function open(page: string): void {
            root.openControlCenter(page);
        }
    }
}
