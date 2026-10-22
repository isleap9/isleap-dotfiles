import QtQuick
import QtQuick.Layouts
import qs

// −  value  +   (scroll on it works too). Bind `value`, handle `changed(newValue)`.
Rectangle {
    id: root

    property real value: 0
    property real from: 0
    property real to: 100
    property real step: 1
    property int decimals: 0
    property string suffix: ""
    signal changed(real newValue)

    function bump(dir) {
        const v = Math.min(to, Math.max(from, value + dir * step));
        const rounded = Number(v.toFixed(decimals));
        if (rounded !== value) changed(rounded);
    }

    implicitWidth: 150
    implicitHeight: 34
    radius: 17
    color: Theme.bg2

    // Inside a page that scrolls, the wheel scrolls the page instead of changing the value
    readonly property Item scroller: {
        for (let p = parent; p; p = p.parent)
            if (p.visibleArea !== undefined && p.contentHeight !== undefined) return p;
        return null;
    }
    readonly property bool wheelChanges: !scroller || scroller.contentHeight <= scroller.height + 1
    WheelHandler { enabled: root.wheelChanges; onWheel: e => root.bump(e.angleDelta.y > 0 ? 1 : -1) }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        StepButton { text: "−"; enabled: root.value > root.from; onPressed: root.bump(-1) }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.value.toFixed(root.decimals) + root.suffix
            color: Theme.fg1
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.Bold
        }
        StepButton { text: "+"; enabled: root.value < root.to; onPressed: root.bump(1) }
    }

    component StepButton: Rectangle {
        id: btn
        property alias text: label.text
        signal pressed
        implicitWidth: 34; implicitHeight: 34; radius: 17
        color: area.containsMouse && enabled ? Theme.bg3 : "transparent"
        opacity: enabled ? 1 : 0.35
        Text {
            id: label
            anchors.centerIn: parent
            color: Theme.fg1
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 3
            font.weight: Font.Bold
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (btn.enabled) btn.pressed()
            // Hold to repeat
            onPressAndHold: repeat.start()
            onReleased: repeat.stop()
        }
        Timer { id: repeat; interval: 70; repeat: true; onTriggered: if (btn.enabled) btn.pressed() }
    }
}
