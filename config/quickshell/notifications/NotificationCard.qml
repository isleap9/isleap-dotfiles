import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs

// One notification. Used for popups and in the notification center.
// Look adapted from tripathiji1312/quickshell (MIT): tonal icon tile, accent stripe,
// hover-lift shadow, image banner, pill actions, slim countdown bar.
Rectangle {
    id: card

    required property Notification notif
    property bool popup: false
    // Set by the popup stack while the card is being swiped
    property bool dragging: false
    // Drop shadow (popups only; the center is already a raised surface)
    property bool elevated: popup
    // Card fill (darker/lighter depending on what it sits on)
    property color surfaceColor: BarConfig.surface(Theme.bg1)

    readonly property int urgency: notif?.urgency ?? NotificationUrgency.Normal
    readonly property bool critical: urgency === NotificationUrgency.Critical
    readonly property color tone: critical ? Theme.red
        : urgency === NotificationUrgency.Low ? Theme.fg2 : Theme.accent
    readonly property bool hovered: hover.containsMouse || closeArea.containsMouse
    readonly property string ago: Notifs.timeAgo(notif)

    // Last known contents. A dismissed notification is destroyed right away, so the card
    // keeps showing these while it animates out.
    property string appName
    property string summary
    property string body
    property string appIcon
    property string image
    property var actions: []
    Binding on appName { when: !!card.notif; value: card.notif?.appName ?? ""; restoreMode: Binding.RestoreNone }
    Binding on summary { when: !!card.notif; value: card.notif?.summary ?? ""; restoreMode: Binding.RestoreNone }
    Binding on body { when: !!card.notif; value: card.notif?.body ?? ""; restoreMode: Binding.RestoreNone }
    Binding on appIcon { when: !!card.notif; value: card.iconPath(card.notif?.appIcon ?? ""); restoreMode: Binding.RestoreNone }
    Binding on image { when: !!card.notif; value: card.iconPath(card.notif?.image ?? ""); restoreMode: Binding.RestoreNone }
    Binding on actions {
        when: !!card.notif
        value: Array.from(card.notif?.actions ?? []).filter(a => a.identifier !== "default")
        restoreMode: Binding.RestoreNone
    }

    function iconPath(icon) {
        if (!icon) return "";
        if (icon.startsWith("/")) return "file://" + icon;
        if (icon.includes("://")) return icon;
        return Quickshell.iconPath(icon, true);
    }

    implicitWidth: 380
    implicitHeight: content.implicitHeight + 34
    radius: 18
    color: surfaceColor
    border.width: 1
    border.color: hovered ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
        : critical ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.3)
        : Qt.rgba(Theme.fg1.r, Theme.fg1.g, Theme.fg1.b, 0.07)
    Behavior on border.color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on implicitHeight { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }

    // Shadow lifts on hover. Drawn by a copy of the card behind it, so if the effect
    // can't render, only the shadow is lost.
    Rectangle {
        z: -1
        anchors.fill: parent
        visible: card.elevated
        radius: parent.radius
        color: "black"
        layer.enabled: card.elevated
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, card.hovered ? 0.30 : 0.18)
            shadowBlur: card.hovered ? 0.9 : 0.55
            shadowVerticalOffset: card.hovered ? 8 : 4
        }
    }

    // Urgency tint (low / critical only)
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        visible: card.urgency !== NotificationUrgency.Normal
        color: Qt.rgba(card.tone.r, card.tone.g, card.tone.b, card.critical ? 0.08 : 0.04)
    }

    // Accent stripe along the top; pulses for critical
    Rectangle {
        anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 1; leftMargin: 20; rightMargin: 20 }
        height: 2.5
        radius: 1.25
        color: card.tone
        opacity: card.urgency === NotificationUrgency.Low ? 0.3 : 0.65
        SequentialAnimation on opacity {
            running: card.critical
            loops: Animation.Infinite
            NumberAnimation { to: 0.3; duration: 1000; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.9; duration: 1000; easing.type: Easing.InOutSine }
        }
    }

    // Hover glow
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Theme.fg1
        opacity: card.hovered && !card.dragging ? 0.035 : 0
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: m => {
            if (!card.notif) return;
            if (m.button === Qt.MiddleButton) { card.notif.dismiss(); return; }
            const def = card.notif.actions.find(a => a.identifier === "default");
            if (def) def.invoke();
            else if (card.popup) Notifs.removePopup(card.notif);
        }
    }

    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16; topMargin: 18 }
        spacing: 8

        // ── Header: icon tile, title + app name, close ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                Layout.alignment: Qt.AlignTop
                radius: 12
                color: Qt.rgba(card.tone.r, card.tone.g, card.tone.b, 0.12)

                IconImage {
                    anchors.centerIn: parent
                    visible: card.appIcon !== ""
                    implicitSize: 20
                    source: card.appIcon
                }
                Text {
                    anchors.centerIn: parent
                    visible: card.appIcon === ""
                    text: card.critical ? "priority_high" : "notifications"
                    color: card.tone
                    opacity: 0.85
                    font.family: Theme.iconFont
                    font.variableAxes: Theme.iconAxesWith(1)
                    font.pixelSize: 18
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: card.summary || "Notification"
                    color: Theme.fg1
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.15
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: [card.appName, card.ago].filter(s => s).join("  ·  ")
                    color: Theme.fg2
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                    elide: Text.ElideRight
                }
            }

            // Close: red tint on hover
            Rectangle {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                Layout.alignment: Qt.AlignTop
                radius: 13
                color: closeArea.containsMouse ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.12) : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
                Text {
                    anchors.centerIn: parent
                    text: "close"
                    color: closeArea.containsMouse ? Theme.red : Qt.rgba(Theme.fg1.r, Theme.fg1.g, Theme.fg1.b, 0.45)
                    Behavior on color { ColorAnimation { duration: 120 } }
                    font.family: Theme.iconFont
                    font.variableAxes: Theme.iconAxes
                    font.pixelSize: 15
                }
                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (card.notif) card.notif.dismiss()
                }
            }
        }

        // ── Body ──
        Text {
            Layout.fillWidth: true
            visible: text !== ""
            text: card.body
            textFormat: Text.StyledText
            color: Theme.fg2
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            lineHeight: 1.3
            wrapMode: Text.Wrap
            maximumLineCount: card.popup ? 3 : 6
            elide: Text.ElideRight
            onLinkActivated: link => Qt.openUrlExternally(link)
        }

        // ── Image banner ──
        ClippingRectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            visible: card.image !== ""
            radius: 10
            color: Theme.bg2
            Image {
                anchors.fill: parent
                source: card.image
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
            }
        }

        // ── Actions as small pills (the hidden "default" action is skipped) ──
        Flow {
            Layout.fillWidth: true
            visible: card.actions.length > 0
            spacing: 6

            Repeater {
                model: card.actions

                Rectangle {
                    id: act
                    required property var modelData
                    width: actLabel.implicitWidth + 22
                    height: 28
                    radius: 14
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, actArea.containsMouse ? 0.18 : 0.10)
                    Behavior on color { ColorAnimation { duration: 120 } }
                    scale: actArea.pressed ? 0.94 : 1
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                    Text {
                        id: actLabel
                        anchors.centerIn: parent
                        text: act.modelData?.text ?? ""
                        color: Theme.accent
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 2
                        font.weight: Font.Medium
                        font.letterSpacing: 0.3
                    }
                    MouseArea {
                        id: actArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (card.notif && act.modelData) act.modelData.invoke()
                    }
                }
            }
        }
    }

    // ── Countdown (popups): drains while shown, pauses on hover/swipe, hidden on hover ──
    property real life: 1
    NumberAnimation {
        target: card
        property: "life"
        from: 1; to: 0
        running: card.popup && !card.critical
        paused: running && (card.hovered || card.dragging)
        duration: card.notif?.expireTimeout > 0 ? card.notif.expireTimeout : Config.notifications.timeout * 1000
        onFinished: if (card.notif) Notifs.removePopup(card.notif)
    }
    Rectangle {
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right; bottomMargin: 7; leftMargin: 18; rightMargin: 18 }
        height: 2
        radius: 1
        visible: card.popup && !card.critical
        opacity: card.hovered ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 150 } }
        color: Qt.rgba(Theme.fg1.r, Theme.fg1.g, Theme.fg1.b, 0.05)
        Rectangle {
            width: parent.width * card.life
            height: parent.height
            radius: 1
            color: Qt.rgba(card.tone.r, card.tone.g, card.tone.b, 0.5)
        }
    }
}
