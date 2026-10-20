import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs

// One row of a Material 3 menu: icon, label, and a checkbox/radio or submenu arrow
Rectangle {
    id: row

    property string label
    property string iconSource: ""
    property string iconText: ""
    property int check: QsMenuButtonType.None
    property bool checked: false
    property bool hasChildren: false
    signal activated

    implicitWidth: content.implicitWidth + 24
    implicitHeight: 42
    radius: 12
    opacity: enabled ? 1 : 0.38
    color: area.containsMouse && enabled ? Theme.bg3 : "transparent"

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (row.enabled) row.activated()
    }

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        // Checkbox / radio
        Rectangle {
            visible: row.check !== QsMenuButtonType.None
            implicitWidth: 18; implicitHeight: 18
            radius: row.check === QsMenuButtonType.RadioButton ? 9 : 4
            color: row.checked ? Theme.accent : "transparent"
            border.width: row.checked ? 0 : 2
            border.color: Theme.fg2
            Text {
                anchors.centerIn: parent
                visible: row.checked
                text: row.check === QsMenuButtonType.RadioButton ? "circle" : "check"
                color: Theme.bg0
                font.family: Theme.iconFont
                font.variableAxes: Theme.iconAxes
                font.pixelSize: row.check === QsMenuButtonType.RadioButton ? 8 : 14
            }
        }
        IconImage {
            visible: row.iconSource !== ""
            implicitSize: 18
            source: row.iconSource
        }
        Text {
            visible: row.iconText !== ""
            text: row.iconText
            color: Theme.fg1
            font.family: Theme.iconFont
            font.variableAxes: Theme.iconAxes
            font.pixelSize: 18
        }
        Text {
            Layout.fillWidth: true
            text: row.label
            elide: Text.ElideRight
            color: Theme.fg1
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
        }
        Text {
            visible: row.hasChildren
            text: "chevron_right"
            color: Theme.fg2
            font.family: Theme.iconFont
            font.variableAxes: Theme.iconAxes
            font.pixelSize: 18
        }
    }
}
