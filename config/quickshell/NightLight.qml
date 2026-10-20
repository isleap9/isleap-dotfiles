pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Night light: warmer screen colors via hyprsunset (install it with `sudo pacman -S hyprsunset`).
//   Config.nightLight.enabled  — on/off (with a schedule: allowed to turn on)
//   schedule: "always" (whenever enabled), "sun" (sunset → sunrise, from the weather data),
//             "custom" (from → to)
Singleton {
    id: root

    property bool installed: false
    readonly property bool enabled: Config.nightLight.enabled
    readonly property int temperature: Config.nightLight.temperature
    readonly property string schedule: Config.nightLight.schedule

    // Is it night right now (for the schedule)?
    property date now: new Date()
    function minutes(d) { return d.getHours() * 60 + d.getMinutes(); }
    function parse(t) { const [h, m] = String(t).split(":").map(Number); return (h || 0) * 60 + (m || 0); }
    readonly property bool inWindow: {
        const n = minutes(now);
        let from, to;
        if (schedule === "sun") {
            const today = WeatherData.daily[0];
            from = today ? minutes(today.sunset) : parse("19:00");
            to = today ? minutes(today.sunrise) : parse("07:00");
        } else if (schedule === "custom") {
            from = parse(Config.nightLight.from);
            to = parse(Config.nightLight.to);
        } else return true;
        return from > to ? (n >= from || n < to) : (n >= from && n < to);
    }
    readonly property bool active: installed && enabled && inWindow
    readonly property string status: !installed ? "Install hyprsunset"
        : !enabled ? "Off"
        : schedule === "always" ? `${temperature}K`
        : active ? `On until ${schedule === "sun" ? "sunrise" : Config.nightLight.to}`
        : `From ${schedule === "sun" ? "sunset" : Config.nightLight.from}`

    function toggle() { Config.nightLight.enabled = !Config.nightLight.enabled; }

    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.now = new Date() }

    Process {
        running: true
        command: ["sh", "-c", "command -v hyprsunset"]
        onExited: code => root.installed = code === 0
    }

    // hyprsunset runs while active; changing the temperature restarts it
    Process {
        id: sunset
        running: root.active
        command: ["hyprsunset", "-t", String(root.temperature)]
    }
    onTemperatureChanged: if (sunset.running) { sunset.running = false; restart.restart(); }
    Timer { id: restart; interval: 300; onTriggered: sunset.running = root.active }
}
