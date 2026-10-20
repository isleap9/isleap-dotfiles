import QtQuick
import QtQuick.Layouts
import qs
import qs.components

// Back arrow + title (+ optional control on the right) for quick settings sub-pages
RowLayout {
    id: root

    property string title
    default property alias extra: slot.data

    Layout.fillWidth: true
    spacing: 8

    MIconButton { icon: "arrow_back"; onClicked: Globals.quickSettingsPage = "main" }
    Text {
        Layout.fillWidth: true
        text: root.title
        color: Theme.fg1
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 5
        font.weight: Font.Bold
    }
    Item {
        id: slot
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }
}
