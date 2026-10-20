pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Audio: output/input devices, their volume and mute, and per-app streams (for the mixer).
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)
    // Apps playing sound (not recorders like cava, which show up as streams too).
    // Stream details only load once tracked, so track every stream, then filter.
    readonly property var allStreams: Pipewire.nodes.values.filter(n => n.audio && n.isStream)
    readonly property var streams: allStreams.filter(n => (n.properties?.["media.class"] ?? "") === "Stream/Output/Audio")

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? false

    PwObjectTracker { objects: [root.sink, root.source, ...root.allStreams, ...root.sinks, ...root.sources] }

    function setVolume(node, v) { if (node?.audio) node.audio.volume = Math.max(0, Math.min(1.5, v)); }
    function toggleMute(node) { if (node?.audio) node.audio.muted = !node.audio.muted; }
    function setSink(n) { Pipewire.preferredDefaultAudioSink = n; }
    function setSource(n) { Pipewire.preferredDefaultAudioSource = n; }

    function name(n) { return n?.description || n?.nickname || n?.name || "Unknown"; }
    function appName(n) {
        const p = n?.properties ?? {};
        return p["application.name"] || p["media.name"] || name(n);
    }
    function appIcon(n) {
        const p = n?.properties ?? {};
        if (p["application.icon-name"]) return p["application.icon-name"];
        // Find the app's own icon from its .desktop entry
        const entry = DesktopEntries.heuristicLookup(p["application.process.binary"] || p["application.name"] || "");
        return entry?.icon || (p["application.process.binary"] ?? "").toLowerCase() || "audio-x-generic";
    }
    function volumeIcon(v, m) {
        if (m || v <= 0.001) return "volume_off";
        if (v < 0.34) return "volume_mute";
        if (v < 0.67) return "volume_down";
        return "volume_up";
    }
    function sinkIcon(n) {
        const s = `${n?.name ?? ""} ${n?.description ?? ""}`.toLowerCase();
        if (s.includes("bluez")) return "bluetooth_connected";
        if (s.includes("hdmi") || s.includes("displayport")) return "monitor";
        if (s.includes("headphone") || s.includes("headset")) return "headphones";
        return "speaker";
    }
}
