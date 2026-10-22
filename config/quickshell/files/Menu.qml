import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs
import qs.components

// M3 menu drawn inside the window. popup(x, y, items) — each item:
// { icon, text, hint, action: function, danger, checked, enabled } or { separator: true }
Item {
    id: menu

    property var items: []
    property bool open: false
    property real px: 0
    property real py: 0

    function popup(x, y, list) {
        items = list.filter(i => i);
        px = x;
        py = y;
        open = true;
    }
    function close() { open = false; }

    anchors.fill: parent
    visible: open || card.opacity > 0
    z: 50

    // Click anywhere else closes it
    MouseArea {
        anchors.fill: parent
        enabled: menu.open
        acceptedButtons: Qt.AllButtons
        onPressed: menu.close()
        onWheel: menu.close()
    }

    Rectangle {
        id: card
        readonly property bool flipX: menu.px + width + 8 > menu.width
        readonly property bool flipY: menu.py + height + 8 > menu.height
        x: Math.max(8, flipX ? menu.px - width : menu.px)
        y: Math.max(8, flipY ? Math.max(8, menu.py - height) : menu.py)
        width: 248
        height: col.implicitHeight + 16
        radius: 18
        color: Theme.bg1
        border.width: 1
        border.color: Qt.rgba(Theme.fg1.r, Theme.fg1.g, Theme.fg1.b, 0.06)

        transformOrigin: flipY ? (flipX ? Item.BottomRight : Item.BottomLeft) : (flipX ? Item.TopRight : Item.TopLeft)
        scale: menu.open ? 1 : 0.88
        opacity: menu.open ? 1 : 0
        Behavior on scale { NumberAnimation { duration: menu.open ? Theme.animMs : Theme.animMs * 0.5; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.emphasizedDecel } }
        Behavior on opacity { NumberAnimation { duration: menu.open ? Theme.animMs * 0.6 : Theme.animMs * 0.4 } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.35)
            shadowBlur: 0.8
            shadowVerticalOffset: 6
        }

        MouseArea { anchors.fill: parent }   // don't let clicks fall through to the catcher

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 8
            spacing: 0

            Repeater {
                model: menu.items

                Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool sep: modelData.separator === true
                    readonly property bool usable: !sep && modelData.enabled !== false

                    Layout.fillWidth: true
                    implicitHeight: sep ? 9 : 40

                    // Items cascade in
                    opacity: menu.open ? 1 : 0
                    transform: Translate {
                        y: menu.open ? 0 : -6
                        Behavior on y { NumberAnimation { duration: Theme.animMs + row.index * 18; easing.type: Easing.OutCubic } }
                    }
                    Behavior on opacity { NumberAnimation { duration: Theme.animMs * 0.6 + row.index * 18 } }

                    Rectangle {
                        visible: row.sep
                        anchors.centerIn: parent
                        width: parent.width - 16
                        height: 1
                        color: Theme.bg2
                    }

                    Rectangle {
                        visible: !row.sep
                        anchors.fill: parent
                        radius: 12
                        color: row.modelData.danger ? Theme.red : Theme.fg1
                        opacity: !row.usable ? 0 : itemArea.pressed ? 0.12 : itemArea.containsMouse ? 0.08 : 0
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }

                    RowLayout {
                        visible: !row.sep
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 14
                        spacing: 12
                        opacity: row.usable ? 1 : 0.38

                        Text {
                            Layout.preferredWidth: 20
                            horizontalAlignment: Text.AlignHCenter
                            text: row.modelData.checked === true ? "check" : row.modelData.icon ?? ""
                            color: row.modelData.danger ? Theme.red : row.modelData.checked ? Theme.accent : Theme.fg2
                            font.family: Theme.iconFont
                            property real fill: itemArea.containsMouse ? 1 : 0
                            Behavior on fill { NumberAnimation { duration: 200 } }
                            font.variableAxes: Theme.iconAxesWith(fill)
                            font.pixelSize: Theme.fontSize + 3
                        }
                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.text ?? ""
                            color: row.modelData.danger ? Theme.red : Theme.fg1
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                            elide: Text.ElideRight
                        }
                        Text {
                            text: row.modelData.hint ?? ""
                            color: Theme.fg2
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 4
                        }
                    }

                    MouseArea {
                        id: itemArea
                        anchors.fill: parent
                        enabled: row.usable
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const act = row.modelData.action;
                            menu.close();
                            if (act) act();
                        }
                    }
                }
            }
        }
    }
}
