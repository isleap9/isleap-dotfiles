import QtQuick
import QtQuick.Layouts
import qs
import qs.components

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

    SmoothWheel { flick: root }
    MScrollBar { flick: root }
}
