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
    property bool dashboardOpen: false
    property string dashboardTab: "overview"     // overview, media, weather
    property ShellScreen dashboardScreen: null   // the screen whose clock was clicked
    property bool settingsOpen: false
    property string settingsPage: "appearance"

    // The screen the user is working on (where popups should appear)
    readonly property ShellScreen focusedScreen: {
        const name = Hyprland.focusedMonitor?.name;
        return Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0];
    }

    // Main monitor (Settings → Monitors), or the biggest screen if none is set / it's unplugged
    readonly property ShellScreen mainScreen: {
        const chosen = Quickshell.screens.find(s => s.name === Config.monitors.main);
        if (chosen) return chosen;
        return [...Quickshell.screens].sort((a, b) => b.width * b.height - a.width * a.height)[0] ?? null;
    }

    // Where the launcher, control center, notifications and power menu open
    readonly property ShellScreen popupScreen: Config.monitors.popups === "main" ? mainScreen : focusedScreen

    function closeAll() {
        launcherOpen = false;
        powerMenuOpen = false;
        notifCenterOpen = false;
        controlCenterOpen = false;
        dashboardOpen = false;
    }

    // Open the dashboard on a tab (again on the same tab closes it). screen: where to show it
    function toggleDashboard(tab, screen) {
        const t = tab || "overview";
        const wasOpen = dashboardOpen && dashboardTab === t;
        closeAll();
        dashboardTab = t;
        dashboardScreen = screen ?? null;
        dashboardOpen = !wasOpen;
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

    // qs ipc call dashboard toggle  /  qs ipc call dashboard open weather
    IpcHandler {
        target: "dashboard"
        function toggle(): void {
            if (root.dashboardOpen) root.dashboardOpen = false;
            else root.toggleDashboard(root.dashboardTab, null);
        }
        function open(tab: string): void { root.toggleDashboard(tab, null); }
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
