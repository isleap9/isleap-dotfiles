import QtQuick
import QtQuick.Layouts
import qs

// Scrollable page body for the Settings app
Flickable {
    id: root

    default property alias content: column.data

    clip: true
    contentWidth: width
    contentHeight: column.implicitHeight + 48
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: column
        x: 28
        y: 24
        width: root.width - 56
        spacing: 26
    }

    // Thin scroll indicator
    Rectangle {
        visible: root.contentHeight > root.height
        x: root.width - 6
        y: root.visibleArea.yPosition * root.height
        width: 4
        height: root.visibleArea.heightRatio * root.height
        radius: 2
        color: Theme.bg3
    }
}
