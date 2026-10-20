import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components

// Material 3 menu for a tray icon, dropping out of the bar under the icon (like the dashboard).
// Replaces the app's own Qt/GTK menu. Submenus open in place, with a back row.
Popout {
    id: root

    property var stack: []               // submenu handles, deepest last
    readonly property var item: Globals.trayMenuItem
    readonly property var menu: stack.length ? stack[stack.length - 1] : item?.menu

    open: item !== null
    screen: Globals.trayMenuScreen
    align: "at"
    atX: Globals.trayMenuX
    namespace: "quickshell-traymenu"
    onClosed: Globals.trayMenuItem = null
    onOpenChanged: stack = []
    onKeyPressed: e => { if (e.key === Qt.Key_Backspace && stack.length) stack = stack.slice(0, -1); }

    content: Component {
        ColumnLayout {
            id: list
            implicitWidth: Math.max(240, Math.min(360, rows.implicitWidth))
            spacing: 0

            QsMenuOpener { id: opener; menu: root.menu ?? null }

            ColumnLayout {
                id: rows
                Layout.fillWidth: true
                spacing: 0

                MenuRow {
                    visible: root.stack.length > 0
                    Layout.fillWidth: true
                    label: "Back"
                    iconText: "arrow_back"
                    onActivated: root.stack = root.stack.slice(0, -1)
                }

                Repeater {
                    model: opener.children

                    Item {
                        id: entry
                        required property var modelData
                        Layout.fillWidth: true
                        implicitWidth: row.implicitWidth
                        implicitHeight: modelData.isSeparator ? 9 : row.implicitHeight

                        Rectangle {
                            visible: entry.modelData.isSeparator
                            anchors.verticalCenter: parent.verticalCenter
                            x: 12
                            width: parent.width - 24
                            height: 1
                            color: Theme.bg3
                        }
                        MenuRow {
                            id: row
                            visible: !entry.modelData.isSeparator
                            width: parent.width
                            label: entry.modelData.text.replace(/_(?!_)/g, "")
                            iconSource: entry.modelData.icon
                            enabled: entry.modelData.enabled
                            check: entry.modelData.buttonType
                            checked: entry.modelData.checkState === Qt.Checked
                            hasChildren: entry.modelData.hasChildren
                            onActivated: {
                                if (entry.modelData.hasChildren) {
                                    root.stack = [...root.stack, entry.modelData];
                                } else {
                                    entry.modelData.triggered();
                                    Globals.trayMenuItem = null;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
