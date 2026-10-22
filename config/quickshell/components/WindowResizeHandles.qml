import QtQuick

// Invisible strips along a window's edges and corners: drag them to resize (the compositor
// does the resizing). Put it last in the window so it sits on top: WindowResizeHandles {}
Item {
    id: root

    property int edge: 6
    property int corner: 14
    property bool active: true

    anchors.fill: parent
    z: 1000
    visible: active

    component Handle: MouseArea {
        property int edges
        cursorShape: {
            const l = edges & Qt.LeftEdge, r = edges & Qt.RightEdge, t = edges & Qt.TopEdge, b = edges & Qt.BottomEdge;
            if ((l && t) || (r && b)) return Qt.SizeFDiagCursor;
            if ((r && t) || (l && b)) return Qt.SizeBDiagCursor;
            return l || r ? Qt.SizeHorCursor : Qt.SizeVerCursor;
        }
        onPressed: Window.window.startSystemResize(edges)
    }

    Handle { edges: Qt.LeftEdge; x: 0; y: root.corner; width: root.edge; height: root.height - 2 * root.corner }
    Handle { edges: Qt.RightEdge; x: root.width - root.edge; y: root.corner; width: root.edge; height: root.height - 2 * root.corner }
    Handle { edges: Qt.TopEdge; x: root.corner; y: 0; width: root.width - 2 * root.corner; height: root.edge }
    Handle { edges: Qt.BottomEdge; x: root.corner; y: root.height - root.edge; width: root.width - 2 * root.corner; height: root.edge }
    Handle { edges: Qt.LeftEdge | Qt.TopEdge; x: 0; y: 0; width: root.corner; height: root.corner }
    Handle { edges: Qt.RightEdge | Qt.TopEdge; x: root.width - root.corner; y: 0; width: root.corner; height: root.corner }
    Handle { edges: Qt.LeftEdge | Qt.BottomEdge; x: 0; y: root.height - root.corner; width: root.corner; height: root.corner }
    Handle { edges: Qt.RightEdge | Qt.BottomEdge; x: root.width - root.corner; y: root.height - root.corner; width: root.corner; height: root.corner }
}
