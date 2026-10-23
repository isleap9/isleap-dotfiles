import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.components

// On-screen display (Material 3): a pill near the bottom of the screen that shows
// volume, microphone mute, brightness, caps lock and keyboard layout changes for a moment.
// Clicks go through it.
Scope {
    id: root

    property string kind: ""            // volume, mic, brightness, caps, layout
    property bool showing: false
    property bool ready: false           // ignore the values reported at startup

    function show(k) {
        if (!ready || !Config.osd.enabled || Config.osd[k] === false) return;
        kind = k;
        showing = true;
        hideTimer.restart();
    }

    Timer { interval: 1500; running: true; onTriggered: root.ready = true }
    Timer { id: hideTimer; interval: Config.osd.duration; onTriggered: root.showing = false }

    Connections {
        target: Audio
        function onVolumeChanged() { root.show("volume"); }
        function onMutedChanged() { root.show("volume"); }
        function onMicMutedChanged() { root.show("mic"); }
        // Switching output device reports a new volume: don't flash for that
        function onSinkChanged() { root.ready = false; readyAgain.restart(); }
    }
    Timer { id: readyAgain; interval: 600; onTriggered: root.ready = true }
    Connections {
        target: Brightness
        function onLevelChanged() { root.show("brightness"); }
    }
    Connections {
        target: Keyboard
        function onCapsLockChanged() { root.show("caps"); }
        function onLayoutSwitched() { root.show("layout"); }
    }

    // Open/close animation (Settings → Animations); "slide" rises from the screen edge
    PanelMotion {
        id: motion
        style: Config.animations.osd
        open: root.showing
        distance: Config.osd.position === "top" ? -40 : 40
    }

    LazyLoader {
        active: motion.needed

        PanelWindow {
            id: win
            screen: Globals.popupScreen
            anchors.bottom: Config.osd.position === "bottom"
            anchors.top: Config.osd.position === "top"
            margins.bottom: 90 - pad
            margins.top: 90 - pad
            exclusionMode: ExclusionMode.Ignore
            // Room around the pill so animations aren't cut off
            readonly property int pad: 40
            implicitWidth: pill.width + pad * 2
            implicitHeight: pill.height + pad * 2
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "quickshell-osd"
            mask: Region {}

            Rectangle {
                id: pill
                anchors.centerIn: parent
                width: row.implicitWidth + 24
                height: 64
                radius: 32
                color: Theme.bg1
                border.width: 1
                border.color: Theme.bg3
                opacity: motion.opacityValue
                scale: motion.scaleValue
                transform: Translate { y: motion.offset }

                readonly property bool isVolume: root.kind === "volume"
                readonly property bool isBrightness: root.kind === "brightness"
                readonly property string icon: ({
                    volume: Audio.volumeIcon(Audio.volume, Audio.muted),
                    mic: Audio.micMuted ? "mic_off" : "mic",
                    brightness: Brightness.level >= 67 ? "brightness_high" : Brightness.level >= 34 ? "brightness_6" : "brightness_4",
                    caps: Keyboard.capsLock ? "keyboard_capslock" : "keyboard_capslock",
                    layout: "keyboard"
                })[root.kind] ?? ""
                readonly property string label: ({
                    volume: Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%",
                    mic: Audio.micMuted ? "Microphone off" : "Microphone on",
                    brightness: Brightness.level + "%",
                    caps: Keyboard.capsLock ? "Caps Lock on" : "Caps Lock off",
                    layout: Keyboard.layout
                })[root.kind] ?? ""
                readonly property bool active: ({
                    volume: !Audio.muted, mic: !Audio.micMuted, brightness: true, caps: Keyboard.capsLock, layout: true
                })[root.kind] ?? true

                RowLayout {
                    id: row
                    anchors.centerIn: parent
                    spacing: 14

                    Rectangle {
                        implicitWidth: 44
                        implicitHeight: 44
                        radius: 22
                        color: pill.active ? Theme.accent : Theme.bg3
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: pill.icon
                            color: pill.active ? Theme.bg0 : Theme.fg1
                            font.family: Theme.iconFont
                            font.variableAxes: Theme.iconAxes
                            font.pixelSize: 22
                        }
                    }
                    MSlider {
                        visible: pill.isVolume || pill.isBrightness
                        implicitWidth: 220
                        interactive: false
                        value: pill.isBrightness ? Brightness.level / 100
                            : Audio.muted ? 0 : Math.min(1, Audio.volume)
                        color: pill.isBrightness ? Theme.accent
                            : Audio.muted ? Theme.fg2 : Theme.accent
                    }
                    Text {
                        Layout.minimumWidth: pill.isVolume || pill.isBrightness ? 48 : 0
                        Layout.rightMargin: 8
                        text: pill.label
                        color: Theme.fg1
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        font.weight: Font.Bold
                        font.features: ({ tnum: 1 })
                    }
                }
            }
        }
    }
}
