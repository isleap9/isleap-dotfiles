import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.components

// Volume. Click: quick settings (sound), right click: mute, middle click: pavucontrol, scroll: ±1%.
Pill {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int volume: Math.round((sink?.audio?.volume ?? 0) * 100)
    readonly property bool bluetooth: (sink?.name ?? "").startsWith("bluez")

    readonly property string icon: {
        if (muted) return "volume_off";
        if (bluetooth) return "bluetooth";
        if (volume < 34) return "volume_mute";
        if (volume < 67) return "volume_down";
        return "volume_up";
    }

    PwObjectTracker { objects: [root.sink] }

    property var screen: null
    onClicked: m => {
        if (m.button === Qt.RightButton) {
            if (sink?.audio) sink.audio.muted = !sink.audio.muted;
        } else if (m.button === Qt.MiddleButton) {
            Quickshell.execDetached(["pavucontrol"]);
        } else {
            Globals.toggleQuickSettings("audio", screen);
        }
    }
    onScrolled: w => {
        if (!sink?.audio) return;
        const step = w.angleDelta.y > 0 ? 0.01 : -0.01;
        sink.audio.volume = Math.max(0, Math.min(1.5, sink.audio.volume + step));
    }

    BarText { icon: true; text: root.icon; color: root.muted ? Theme.red : root.iconColor }
    ColumnLayout {
        visible: BarConfig.opt(root.settings, "label")
        Layout.alignment: Qt.AlignVCenter
        spacing: 1
        BarText {
            text: root.muted ? "Muted" : root.volume + "%"
            font.features: ({ tnum: 1 })
            Layout.preferredHeight: BarConfig.textSize + 4
        }
        // Level bar
        Rectangle {
            visible: BarConfig.opt(root.settings, "level") !== false
            Layout.fillWidth: true
            implicitHeight: 3
            radius: 1.5
            color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.2)
            Rectangle {
                width: parent.width * Math.min(1, root.muted ? 0 : root.volume / 100)
                height: parent.height
                radius: parent.radius
                color: BarConfig.accentColor
                Behavior on width { NumberAnimation { duration: 150 } }
            }
        }
    }
}
