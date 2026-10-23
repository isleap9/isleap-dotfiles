pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray

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
    property bool quickSettingsOpen: false
    property string quickSettingsPage: "main"    // main, wifi, bluetooth, audio
    property ShellScreen quickSettingsScreen: null
    // Keep awake (saved in config.json, so a shell reload doesn't turn it off)
    readonly property bool keepAwake: Config.session.keepAwake
    function setKeepAwake(on) { Config.session.keepAwake = on; }
    // Backup for suspend: hold a systemd sleep/idle block while keep awake is on
    Process {
        running: root.keepAwake
        // Ends by itself when the shell exits (waits on the shell's process), so it can't get stuck
        command: ["systemd-inhibit", "--what=sleep:idle", "--who=Quickshell", "--why=Keep awake is on",
            "sh", "-c", "exec tail --pid=\"$(ps -o ppid= -p $PPID | tr -d ' ')\" -f /dev/null"]
    }
    property bool overviewOpen: false
    // Tray menu (drops out of the bar under the icon)
    property var trayMenuItem: null
    property ShellScreen trayMenuScreen: null
    property real trayMenuX: 0               // stop the screen from sleeping / locking
    property var barWidths: ({})                 // screen name → bar width (for lining popouts up with it)
    // A popout flush with one end of the bar ("screen:left" / "screen:right"): that bar corner goes square
    property string barJoin: ""
    property bool settingsOpen: false
    property string settingsPage: "appearance"
    // File explorer windows: one entry per open window ({ id, path }), so several can be open
    property var filesWindows: []
    property int nextFilesId: 1
    readonly property bool filesOpen: filesWindows.length > 0

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
        quickSettingsOpen = false;
        trayMenuItem = null;
    }

    // Quick settings on a page (again on the same page closes it)
    function toggleQuickSettings(page, screen) {
        const p = page || "main";
        const wasOpen = quickSettingsOpen && quickSettingsPage === p;
        closeAll();
        quickSettingsPage = p;
        quickSettingsScreen = screen ?? null;
        quickSettingsOpen = !wasOpen;
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

    // Icon for an app id / window class. Tries the .desktop entry's icon, then common variants
    // (Spotify's entry asks for "spotify-client" but the theme has "spotify").
    function appIcon(appId) {
        const id = appId ?? "";
        const entry = DesktopEntries.heuristicLookup(id);
        const last = id.split(".").pop();
        const tries = [entry?.icon, id, id.toLowerCase(), last, last.toLowerCase(),
            id.toLowerCase().replace(/ /g, "-"), (entry?.icon ?? "").replace(/-client$/, ""),
            last.toLowerCase() === "vscode" ? "visual-studio-code" : ""];
        for (const t of tries) {
            if (!t) continue;
            const p = Quickshell.iconPath(t, true);
            if (p) return p;
        }
        // Some apps only put their icon in /usr/share/pixmaps
        for (const t of tries) {
            if (t && pixmaps[t]) return "file:///usr/share/pixmaps/" + pixmaps[t];
        }
        return Quickshell.iconPath("application-x-executable");
    }
    property var pixmaps: ({})       // icon name → file in /usr/share/pixmaps
    Process {
        running: true
        command: ["ls", "/usr/share/pixmaps"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = {};
                for (const f of text.split("\n")) {
                    const n = f.replace(/\.(png|svg|xpm)$/, "");
                    if (n && n !== f) m[n] = f;
                }
                root.pixmaps = m;
            }
        }
    }

    function run(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    // Screen recording (wf-recorder, from the control center's Capture page)
    property bool recording: false

    function startRecording(cmd) {
        recording = true;
        run(cmd);
    }

    // SIGINT makes wf-recorder finalize (close) the mp4 before it exits;
    // SIGTERM/SIGKILL would leave a broken file.
    function stopRecording() {
        if (!recording) return;
        recording = false;
        run(`pkill -INT -x wf-recorder; sleep 1; notify-send -i video-camera "Recording stopped" "Saved to ~/Videos"`);
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

    // Files is a normal window too. Every call opens another window (empty path = home).
    function openFiles(path) {
        controlCenterOpen = false;
        filesWindows = filesWindows.concat([{ id: nextFilesId++, path: path || "" }]);
    }
    function closeFiles(id) {
        filesWindows = filesWindows.filter(w => w.id !== id);
    }

    // qs ipc call files launch  /  qs ipc call files open ~/Downloads  (both open a new window)
    // qs ipc call files toggle — open one if none is open, otherwise close them all
    // qs ipc call files closeAll
    IpcHandler {
        target: "files"
        function launch(): void { root.openFiles(""); }
        function open(path: string): void { root.openFiles(path); }
        function toggle(): void {
            if (root.filesOpen) root.filesWindows = [];
            else root.openFiles("");
        }
        function closeAll(): void { root.filesWindows = []; }
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
            else root.toggleDashboard(Config.dashboard.openOn === "last" ? root.dashboardTab : Config.dashboard.openOn, null);
        }
        function open(tab: string): void { root.toggleDashboard(tab, null); }
    }

    // qs ipc call hovercard preview clock — show a widget's hover card for 4 s (clock, weather)
    property string hoverPreview: ""
    Timer { id: previewTimer; interval: 4000; onTriggered: root.hoverPreview = "" }
    IpcHandler {
        target: "hovercard"
        function preview(name: string): void { root.hoverPreview = name; previewTimer.restart(); }
    }

    // qs ipc call panels closeAll — close every popup/panel
    IpcHandler {
        target: "panels"
        function closeAll(): void { root.closeAll(); }
    }

    // qs ipc call keepawake on / off / toggle
    IpcHandler {
        target: "keepawake"
        function on(): void { root.setKeepAwake(true); }
        function off(): void { root.setKeepAwake(false); }
        function toggle(): void { root.setKeepAwake(!root.keepAwake); }
    }

    // qs ipc call traymenu open discord 3300  — open a tray app's menu (name match) under screen x
    IpcHandler {
        target: "traymenu"
        function open(name: string, x: real): void {
            const item = SystemTray.items.values.find(i => `${i.id} ${i.title}`.toLowerCase().includes(name.toLowerCase()));
            if (!item) return;
            root.closeAll();
            root.trayMenuScreen = root.focusedScreen;
            root.trayMenuX = x;
            root.trayMenuItem = item;
        }
    }

    // qs ipc call overview toggle
    IpcHandler {
        target: "overview"
        function toggle(): void {
            const open = !root.overviewOpen;
            root.closeAll();
            root.overviewOpen = open;
        }
    }

    // qs ipc call quicksettings toggle  /  qs ipc call quicksettings open audio
    IpcHandler {
        target: "quicksettings"
        function toggle(): void {
            if (root.quickSettingsOpen) root.quickSettingsOpen = false;
            else root.toggleQuickSettings("main", null);
        }
        function open(page: string): void { root.toggleQuickSettings(page, null); }
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
