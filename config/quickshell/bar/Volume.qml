import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.components

// Volume. Click: pavucontrol, right click: mute, scroll: ±1%.
Pill {
    id: root
    shown: Config.bar.modules.volume

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int volume: Math.round((sink?.audio?.volume ?? 0) * 100)
    readonly property bool bluetooth: (sink?.name ?? "").startsWith("bluez")

    readonly property string icon: {
        if (muted) return "󰝟";
        if (bluetooth) return "󰂯";
        if (volume < 34) return "󰕿";
        if (volume < 67) return "󰖀";
        return "󰕾";
    }

    PwObjectTracker { objects: [root.sink] }

    onClicked: m => {
        if (m.button === Qt.RightButton) {
            if (sink?.audio) sink.audio.muted = !sink.audio.muted;
        } else {
            Quickshell.execDetached(["pavucontrol"]);
        }
    }
    onScrolled: w => {
        if (!sink?.audio) return;
        const step = w.angleDelta.y > 0 ? 0.01 : -0.01;
        sink.audio.volume = Math.max(0, Math.min(1.5, sink.audio.volume + step));
    }

    BarText { icon: true; text: root.icon }
    BarText { text: root.muted ? "Muted" : root.volume + "%" }
}
