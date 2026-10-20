import QtQuick
import QtQuick.Layouts
import qs

// One shared pill holding several modules (Waybar's .modules-right / .modules-center
// background in the default2 and minimal layouts). Children are made flat automatically.
Rectangle {
    id: group

    default property alias content: row.data
    property int padding: 18

    implicitHeight: Theme.barHeight
    implicitWidth: row.implicitWidth + padding * 2
    radius: height / 2
    color: Theme.bg1

    Behavior on implicitWidth { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spacing
    }

    Component.onCompleted: {
        for (const child of row.children)
            if (child.flat !== undefined) child.flat = true;
    }
}
