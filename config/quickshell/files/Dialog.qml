import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs
import qs.components

// M3 basic dialog inside the window: a name prompt (rename / new folder) or a yes/no question.
// ask({ icon, title, body, value, placeholder, confirm, danger, selectStem, onAccept: function(text) })
Item {
    id: dlg

    property var opts: ({})
    property bool open: false
    readonly property bool hasInput: opts.value !== undefined
    property string error: ""

    function ask(o) {
        opts = o;
        error = "";
        input.text = o.value ?? "";
        open = true;
        if (hasInput) {
            input.forceActiveFocus();
            // Select the name without its extension, like other file managers
            const dot = input.text.lastIndexOf(".");
            if (o.selectStem && dot > 0) input.select(0, dot);
            else input.selectAll();
        } else {
            card.forceActiveFocus();
        }
    }
    function close() { open = false; }
    function accept() {
        if (hasInput) {
            const t = input.text.trim();
            if (t === "" || t === "." || t === "..") { error = "Enter a name"; return; }
            if (t.indexOf("/") >= 0) { error = "Names can't contain /"; return; }
        }
        const cb = opts.onAccept;
        close();
        if (cb) cb(input.text.trim());
    }

    anchors.fill: parent
    visible: open || scrim.opacity > 0
    z: 60

    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "black"
        opacity: dlg.open ? 0.4 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animMs * 0.7 } }
        MouseArea { anchors.fill: parent; enabled: dlg.open; onClicked: dlg.close() }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 380
        height: content.implicitHeight + 48
        radius: 28
        color: Theme.bg1
        scale: dlg.open ? 1 : 0.9
        opacity: dlg.open ? 1 : 0
        Behavior on scale { NumberAnimation { duration: Theme.animMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.emphasizedDecel } }
        Behavior on opacity { NumberAnimation { duration: Theme.animMs * 0.6 } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.4)
            shadowBlur: 1
            shadowVerticalOffset: 10
        }

        Keys.onReturnPressed: dlg.accept()
        Keys.onEnterPressed: dlg.accept()
        Keys.onEscapePressed: dlg.close()

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: dlg.opts.icon ?? ""
                visible: text !== ""
                color: dlg.opts.danger ? Theme.red : Theme.accent
                font.family: Theme.iconFont
                font.variableAxes: Theme.iconAxesWith(1)
                font.pixelSize: 26
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: dlg.opts.title ?? ""
                color: Theme.fg1
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 5
                wrapMode: Text.Wrap
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: dlg.opts.body ?? ""
                color: Theme.fg2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                wrapMode: Text.Wrap
            }

            // Outlined text field
            Rectangle {
                visible: dlg.hasInput
                Layout.fillWidth: true
                implicitHeight: 52
                radius: 14
                color: "transparent"
                border.width: input.activeFocus ? 2 : 1
                border.color: dlg.error ? Theme.red : input.activeFocus ? Theme.accent : Theme.fg2
                Behavior on border.color { ColorAnimation { duration: 150 } }

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    color: Theme.fg1
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.bg0
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    onTextChanged: dlg.error = ""
                    Keys.onReturnPressed: dlg.accept()
                    Keys.onEnterPressed: dlg.accept()
                    Keys.onEscapePressed: dlg.close()

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: input.text === ""
                        text: dlg.opts.placeholder ?? ""
                        color: Theme.fg2
                        font: input.font
                    }
                }
            }
            Text {
                visible: dlg.error !== ""
                text: dlg.error
                color: Theme.red
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 3
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                Layout.topMargin: 4
                spacing: 8

                TextButton { text: "Cancel"; onClicked: dlg.close() }
                TextButton {
                    text: dlg.opts.confirm ?? "OK"
                    filled: true
                    danger: dlg.opts.danger === true
                    onClicked: dlg.accept()
                }
            }
        }
    }

    component TextButton: Rectangle {
        id: btn
        property string text
        property bool filled: false
        property bool danger: false
        signal clicked
        implicitHeight: 40
        implicitWidth: label.implicitWidth + 40
        radius: btnArea.pressed ? 12 : 20
        Behavior on radius { NumberAnimation { duration: 120 } }
        color: filled ? (danger ? Theme.red : Theme.accent) : "transparent"
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: btn.filled ? Theme.bg0 : Theme.accent
            opacity: btnArea.pressed ? 0.12 : btnArea.containsMouse ? 0.08 : 0
        }
        Text {
            id: label
            anchors.centerIn: parent
            text: btn.text
            color: btn.filled ? Theme.bg0 : Theme.accent
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.DemiBold
        }
        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
