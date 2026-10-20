import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// Popups in a corner of the focused monitor.
// Motion adapted from tripathiji1312/quickshell (MIT): cards drop in with a soft bounce,
// tilt as you swipe them, and fly off to the side (or shrink away when they time out).
PanelWindow {
    id: win

    // Room around the cards so their shadows aren't cut off
    readonly property int pad: 14
    readonly property int cardWidth: 380

    // Corner from Settings → Notifications
    readonly property string pos: Config.notifications.position
    readonly property bool onBottom: pos.startsWith("bottom")
    readonly property bool onLeft: pos.endsWith("left")

    // Stay mapped a moment after the last popup leaves so its exit animation can finish
    property bool lingering: false
    readonly property bool hasPopups: Notifs.popups.length > 0
    onHasPopupsChanged: if (!hasPopups) { lingering = true; lingerTimer.restart(); }
    Timer { id: lingerTimer; interval: 600; onTriggered: win.lingering = false }

    screen: Globals.popupScreen
    visible: (hasPopups || lingering) && !Globals.notifCenterOpen

    anchors.top: !onBottom
    anchors.bottom: onBottom
    anchors.left: onLeft
    anchors.right: !onLeft
    margins.top: 8 - pad
    margins.bottom: 16 - pad
    margins.left: Theme.barSideMargin - pad
    margins.right: Theme.barSideMargin - pad
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    // A fixed tall surface, so cards can animate without the window resizing under them.
    // Only the area covered by cards takes input.
    implicitWidth: cardWidth + pad * 2
    implicitHeight: Math.max(200, (screen?.height ?? 1080) * 0.8)
    color: "transparent"
    mask: Region { item: hitArea }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"

    Item {
        id: hitArea
        x: win.pad
        width: win.cardWidth
        height: Math.min(list.height, list.contentHeight)
        y: win.onBottom ? parent.height - win.pad - height : win.pad
    }

    ListView {
        id: list
        anchors.fill: parent
        anchors.margins: win.pad
        interactive: false
        spacing: 10
        verticalLayoutDirection: win.onBottom ? ListView.BottomToTop : ListView.TopToBottom
        model: ScriptModel { values: Notifs.popups.slice(0, Config.notifications.maxPopups) }

        delegate: Item {
            id: slot
            required property var modelData

            width: ListView.view.width
            height: card.implicitHeight

            // Entry progress 0 → 1 (driven by the add transition, style from Settings → Animations)
            property real enterP: 1
            readonly property string style: Config.animations.popups
            // Exit (driven by the remove transition): 0 → 1
            property real leave: 0
            // Swipe
            property real dragX: 0
            property bool swiped: false
            readonly property int exitSign: dragX >= 0 ? 1 : -1
            readonly property real threshold: width * 0.3

            function swipeAway() {
                swiped = true;
                if (modelData) Notifs.removePopup(modelData);
            }

            // Hint behind the card: close when swiping right, check when swiping left
            Rectangle {
                anchors.fill: card
                radius: card.radius
                visible: !slot.swiped && Math.abs(slot.dragX) > 20
                opacity: Math.min(0.85, Math.abs(slot.dragX) / (slot.threshold * 1.5))
                color: slot.dragX > 0 ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.08)
                                      : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)
                Text {
                    anchors.centerIn: parent
                    text: slot.dragX > 0 ? "close" : "check"
                    color: slot.dragX > 0 ? Theme.red : Theme.accent
                    opacity: 0.6
                    font.family: Theme.iconFont
                    font.variableAxes: Theme.iconAxes
                    font.pixelSize: 26
                }
            }

            NotificationCard {
                id: card
                notif: slot.modelData
                popup: true
                dragging: swipe.active
                width: parent.width

                // "slide" comes in sideways from the screen edge; the others use the shared styles
                x: slot.dragX
                   + (slot.style === "slide" ? (1 - slot.enterP) * (win.onLeft ? -1 : 1) * slot.width * 0.6 : 0)
                   + (slot.swiped ? slot.leave * slot.exitSign * (slot.width + 60) : 0)
                transform: Translate { y: slot.style === "slide" ? 0 : Motion.offset(slot.style, slot.enterP, win.onBottom ? 28 : -28) }
                transformOrigin: Item.Top
                rotation: slot.dragX * 0.015 + (slot.swiped ? slot.leave * 4 * slot.exitSign : 0)
                scale: Motion.scale(slot.style, slot.enterP) * (slot.swiped ? 1 : 1 - 0.12 * slot.leave)
                opacity: Motion.opacity(slot.style, slot.enterP) * (1 - slot.leave)
            }

            // Drag sideways to tuck the popup away (it stays in the notification center)
            DragHandler {
                id: swipe
                target: null
                yAxis.enabled: false
                onTranslationChanged: if (active) slot.dragX = translation.x * 0.8
                onActiveChanged: {
                    if (active) { snapBack.stop(); return; }
                    if (Math.abs(slot.dragX) > slot.threshold) slot.swipeAway();
                    else snapBack.start();
                }
            }
            // Two-finger trackpad swipe does the same
            WheelHandler {
                orientation: Qt.Horizontal
                acceptedDevices: PointerDevice.TouchPad
                onWheel: e => {
                    slot.dragX += e.angleDelta.x * 0.5;
                    wheelIdle.restart();
                    if (Math.abs(slot.dragX) > slot.threshold) { wheelIdle.stop(); slot.swipeAway(); }
                }
            }
            Timer {
                id: wheelIdle
                interval: 300
                onTriggered: if (!slot.swiped) snapBack.start()
            }
            NumberAnimation {
                id: snapBack
                target: slot; property: "dragX"; to: 0
                duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.3
            }
        }

        add: Transition {
            NumberAnimation {
                property: "enterP"
                from: 0; to: 1
                duration: Math.max(1, Motion.openMs(Config.animations.popups))
                easing.type: Config.animations.popups === "bounce" ? Easing.OutBack : Easing.BezierSpline
                easing.overshoot: 1.4
                easing.bezierCurve: Motion.emphasizedDecel
            }
        }

        // Fly off when swiped, shrink away when timed out / closed
        remove: Transition {
            NumberAnimation { property: "leave"; to: 1; duration: Math.max(1, Motion.closeMs(Config.animations.popups)); easing.type: Easing.InCubic }
        }

        // The rest of the stack slides into place; also finish any interrupted entry
        displaced: Transition {
            NumberAnimation { property: "y"; duration: 280; easing.type: Easing.OutCubic }
            NumberAnimation { property: "enterP"; to: 1; duration: 200 }
        }
    }
}
