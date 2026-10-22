import QtQuick
import QtQuick.Shapes
import qs

// Pac-Man and a pellet (the "classic" workspace style's active mark), drawn as a shape so it
// follows the Material look instead of a Nerd Font glyph. chomp() makes him take a few bites.
Item {
    id: root

    property color color: Theme.fg1
    property int size: 13
    property real mouth: 70           // how far the mouth is open, in degrees

    function chomp() {
        if (Theme.animMs > 0) bites.restart();
    }

    implicitWidth: size + pellet.width + 2
    implicitHeight: size

    Shape {
        width: root.size
        height: root.size
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            startX: root.size / 2
            startY: root.size / 2
            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.size / 2
                radiusY: root.size / 2
                startAngle: root.mouth / 2
                sweepAngle: 360 - root.mouth
            }
            PathLine { x: root.size / 2; y: root.size / 2 }
        }
    }
    Rectangle {
        id: pellet
        x: root.size + 2 - (root.size * 0.35) * (1 - root.mouth / 70)
        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(root.size * 0.24)
        height: width
        radius: width / 2
        color: root.color
    }

    SequentialAnimation {
        id: bites
        loops: 3
        NumberAnimation { target: root; property: "mouth"; to: 4; duration: 90; easing.type: Easing.InQuad }
        NumberAnimation { target: root; property: "mouth"; to: 70; duration: 120; easing.type: Easing.OutQuad }
    }
}
