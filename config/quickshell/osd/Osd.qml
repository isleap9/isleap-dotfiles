import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.components

// On-screen display (Material 3): a pill near the bottom of the screen that shows
// volume, microphone mute, caps lock and keyboard layout changes for a moment.
// Clicks go through it.
Scope {
    id: root

    property string kind: ""            // volume, mic, caps, layout
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
        target: Keyboard
        function onCapsLockChanged() { root.show("caps"); }
        function onLayoutSwitched() { root.show("layout"); }
    }

    // Keep the window a moment after hiding, so it can fade out
    onShowingChanged: if (!showing) linger.restart()
    Timer { id: linger; interval: 250 }

    LazyLoader {
        active: root.showing || linger.running

        PanelWindow {
            id: win
            screen: Globals.popupScreen
            anchors.bottom: Config.osd.position === "bottom"
            anchors.top: Config.osd.position === "top"
            margins.bottom: 90
            margins.top: 90
            exclusionMode: ExclusionMode.Ignore
            implicitWidth: pill.width
            implicitHeight: pill.height
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "quickshell-osd"
            mask: Region {}

            Rectangle {
                id: pill
                width: row.implicitWidth + 24
                height: 64
                radius: 32
                color: Theme.bg1
                border.width: 1
                border.color: Theme.bg3
                opacity: root.showing ? 1 : 0
                scale: root.showing ? 1 : 0.92
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                readonly property bool isVolume: root.kind === "volume"
                readonly property string icon: ({
                    volume: Audio.volumeIcon(Audio.volume, Audio.muted),
                    mic: Audio.micMuted ? "mic_off" : "mic",
                    caps: Keyboard.capsLock ? "keyboard_capslock" : "keyboard_capslock",
                    layout: "keyboard"
                })[root.kind] ?? ""
                readonly property string label: ({
                    volume: Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%",
                    mic: Audio.micMuted ? "Microphone off" : "Microphone on",
                    caps: Keyboard.capsLock ? "Caps Lock on" : "Caps Lock off",
                    layout: Keyboard.layout
                })[root.kind] ?? ""
                readonly property bool active: ({
                    volume: !Audio.muted, mic: !Audio.micMuted, caps: Keyboard.capsLock, layout: true
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
                        visible: pill.isVolume
                        implicitWidth: 220
                        interactive: false
                        value: Audio.muted ? 0 : Math.min(1, Audio.volume)
                        color: Audio.muted ? Theme.fg2 : Theme.accent
                    }
                    Text {
                        Layout.minimumWidth: pill.isVolume ? 48 : 0
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
