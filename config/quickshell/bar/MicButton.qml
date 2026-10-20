import QtQuick
import qs
import qs.components

// Microphone: click to mute/unmute, scroll for its volume, right click: sound menu
Pill {
    id: root
    active: !Audio.micMuted
    property var screen: null
    onClicked: m => m.button === Qt.RightButton ? Globals.toggleQuickSettings("audio", screen) : Audio.toggleMute(Audio.source)
    onScrolled: w => Audio.setVolume(Audio.source, Audio.micVolume + (w.angleDelta.y > 0 ? 0.02 : -0.02))
    BarText {
        icon: true
        text: Audio.micMuted ? "mic_off" : "mic"
        color: Audio.micMuted ? Theme.red : root.iconColor
    }
    BarText { visible: BarConfig.opt(root.settings, "label") === true; text: Math.round(Audio.micVolume * 100) + "%" }
}
