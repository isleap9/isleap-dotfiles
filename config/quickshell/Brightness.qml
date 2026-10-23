pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Screen brightness: dims the screen with hyprsunset's gamma flag
// (`hyprsunset -g <percent>`, lower = dimmer), because this setup has no backlight device.
//   Config.brightness.level — 5 to 100 (100 = normal)
//   qs ipc call brightness raise / lower / set <level>
// Brightness and Night Light share ONE hyprsunset process (it runs while either needs it).
Singleton {
    id: root

    property bool installed: false
    readonly property int level: Config.brightness.level

    // Run hyprsunset only when it has something to do: dimming or a night light temperature
    readonly property bool needsProcess: installed && (level < 100 || NightLight.active)
    readonly property int temperature: NightLight.active ? NightLight.temperature : 6000

    function set(v) { Config.brightness.level = Math.round(Math.max(5, Math.min(100, v))); }
    function raise() { set(level + 5); }
    function lower() { set(level - 5); }

    Component.onCompleted: update()

    // hyprsunset runs while needed; it must be restarted to pick up new arguments
    Process {
        id: sunset
        command: ["hyprsunset", "-t", String(root.temperature), "-g", String(root.level)]
    }
    function update() {
        if (!root.needsProcess) { sunset.running = false; return; }
        // A running process keeps its old arguments, so restart it either way
        sunset.running = false;
        restartTimer.restart();
    }
    onLevelChanged: update()
    onTemperatureChanged: update()
    onNeedsProcessChanged: update()
    Timer { id: restartTimer; interval: 300; onTriggered: sunset.running = root.needsProcess }

    Process {
        running: true
        command: ["sh", "-c", "command -v hyprsunset"]
        onExited: code => root.installed = code === 0
    }

    // qs ipc call brightness raise / lower / set 60
    IpcHandler {
        target: "brightness"
        function raise(): void { root.raise(); }
        function lower(): void { root.lower(); }
        function set(level: int): void { root.set(level); }
    }
}
