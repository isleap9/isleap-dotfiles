import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs
import qs.components

// "Open with…": apps that handle the file's type (default first), or any app via search / "All apps".
// "Always use" makes the chosen app the default for that type (xdg-mime).
Item {
    id: dlg

    property var explorer
    property bool open: false
    property var paths: []
    property string mime: ""
    property string defaultId: ""
    property var recommended: []      // DesktopEntry objects
    property bool showAll: false
    property bool makeDefault: false
    property string filter: ""

    readonly property string firstName: paths.length ? explorer.baseName(paths[0]) : ""
    readonly property var allApps: DesktopEntries.applications.values
        .filter(a => !a.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))
    readonly property var shown: {
        const q = filter.toLowerCase();
        if (q) return allApps.filter(a => a.name.toLowerCase().includes(q) || (a.genericName ?? "").toLowerCase().includes(q));
        if (showAll) return recommended.concat(allApps.filter(a => recommended.indexOf(a) < 0));
        return recommended;
    }

    function ask(list) {
        paths = list;
        mime = "";
        defaultId = "";
        recommended = [];
        showAll = false;
        makeDefault = false;
        search.text = "";
        lookup.running = false;
        lookup.running = true;
        open = true;
        card.forceActiveFocus();
    }
    function close() { open = false; }

    function entryFor(id) {
        const bare = id.replace(/\.desktop$/, "");
        return DesktopEntries.byId(bare) ?? null;
    }
    function launch(app) {
        if (makeDefault && mime)
            Quickshell.execDetached(["xdg-mime", "default", app.id + ".desktop", mime]);
        explorer.launchApp(app, paths);
        if (makeDefault) explorer.toast(app.name + " is now the default for " + mime);
        close();
    }

    Process {
        id: lookup
        command: ["sh", Quickshell.shellDir + "/scripts/files-openwith.sh", dlg.paths[0] ?? ""]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").map(l => l.trim());
                dlg.mime = lines[0] ?? "";
                dlg.defaultId = (lines[1] ?? "").replace(/\.desktop$/, "");
                const seen = {}, list = [];
                for (const id of [lines[1] ?? ""].concat(lines.slice(2))) {
                    const e = id ? dlg.entryFor(id) : null;
                    if (!e || seen[e.id]) continue;
                    seen[e.id] = true;
                    list.push(e);
                }
                dlg.recommended = list;
                if (list.length === 0) dlg.showAll = true;
            }
        }
    }

    anchors.fill: parent
    visible: open || scrim.opacity > 0
    z: 60

    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "black"
        opacity: dlg.open ? 0.4 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animMs * 0.7 } }
        MouseArea { anchors.fill: parent; enabled: dlg.open; onClicked: dlg.close() }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 440
        height: Math.min(parent.height - 80, 580)
        radius: 28
        color: Theme.bg1
        scale: dlg.open ? 1 : 0.9
        opacity: dlg.open ? 1 : 0
        Behavior on scale { NumberAnimation { duration: Theme.animMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.emphasizedDecel } }
        Behavior on opacity { NumberAnimation { duration: Theme.animMs * 0.6 } }
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.4)
            shadowBlur: 1
            shadowVerticalOffset: 10
        }

        Keys.onEscapePressed: dlg.close()
        Keys.onPressed: event => {
            // Typing filters the list
            if (event.text.length === 1 && event.text > " " && !(event.modifiers & Qt.ControlModifier)) {
                search.forceActiveFocus();
                search.text += event.text;
                event.accepted = true;
            }
        }
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 14

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "apps"
                color: Theme.accent
                font.family: Theme.iconFont
                font.variableAxes: Theme.iconAxesWith(1)
                font.pixelSize: 26
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: dlg.paths.length > 1 ? `Open ${dlg.paths.length} files with` : `Open “${dlg.firstName}” with`
                color: Theme.fg1
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 4
                elide: Text.ElideMiddle
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                visible: dlg.mime !== ""
                text: dlg.mime
                color: Theme.fg2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 3
            }

            // Search
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 44
                radius: 22
                color: Theme.bg0
                border.width: search.activeFocus ? 2 : 0
                border.color: Theme.accent
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 8
                    Text {
                        text: "search"
                        color: search.activeFocus ? Theme.accent : Theme.fg2
                        font.family: Theme.iconFont
                        font.variableAxes: Theme.iconAxes
                        font.pixelSize: Theme.fontSize + 4
                    }
                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        clip: true
                        color: Theme.fg1
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.bg0
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                        onTextChanged: { dlg.filter = text.trim(); appList.currentIndex = 0; }
                        Keys.onEscapePressed: dlg.close()
                        Keys.onDownPressed: appList.incrementCurrentIndex()
                        Keys.onUpPressed: appList.decrementCurrentIndex()
                        Keys.onReturnPressed: if (dlg.shown[appList.currentIndex]) dlg.launch(dlg.shown[appList.currentIndex])
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: search.text === ""
                            text: "Search all apps"
                            color: Theme.fg2
                            font: search.font
                        }
                    }
                }
            }

            ListView {
                SmoothWheel { flick: appList }
                MScrollBar { flick: appList }
                id: appList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                model: dlg.shown
                currentIndex: 0
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool isDefault: modelData.id === dlg.defaultId
                    readonly property bool current: ListView.isCurrentItem && search.activeFocus
                    width: appList.width
                    height: 52
                    radius: 26
                    color: current ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16) : "transparent"
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Theme.fg1
                        opacity: rowArea.pressed ? 0.12 : rowArea.containsMouse ? 0.08 : 0
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 14
                        spacing: 12
                        IconImage {
                            implicitSize: 32
                            source: Globals.appIcon(row.modelData.id)
                            asynchronous: true
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.name
                                color: Theme.fg1
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 1
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: row.modelData.genericName ?? ""
                                color: Theme.fg2
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 4
                                elide: Text.ElideRight
                            }
                        }
                        // "Default" chip
                        Rectangle {
                            visible: row.isDefault
                            implicitHeight: 24
                            implicitWidth: defLabel.implicitWidth + 20
                            radius: 12
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2)
                            Text {
                                id: defLabel
                                anchors.centerIn: parent
                                text: "Default"
                                color: Theme.accent
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 4
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dlg.launch(row.modelData)
                    }
                }

                // "All apps" at the end of the recommended list
                footer: Item {
                    width: appList.width
                    height: !dlg.showAll && dlg.filter === "" ? 52 : 0
                    visible: height > 0
                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 4
                        radius: 24
                        color: Theme.fg1
                        opacity: allArea.pressed ? 0.12 : allArea.containsMouse ? 0.08 : 0
                    }
                    RowLayout {
                        anchors.fill: parent
                        anchors.topMargin: 4
                        anchors.leftMargin: 16
                        spacing: 16
                        Text {
                            text: "apps"
                            color: Theme.accent
                            font.family: Theme.iconFont
                            font.variableAxes: Theme.iconAxes
                            font.pixelSize: Theme.fontSize + 6
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Show all apps"
                            color: Theme.accent
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                            font.weight: Font.DemiBold
                        }
                    }
                    MouseArea {
                        id: allArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dlg.showAll = true
                    }
                }
            }

            // Always use
            RowLayout {
                Layout.fillWidth: true
                visible: dlg.mime !== ""
                spacing: 12
                Text {
                    Layout.fillWidth: true
                    text: "Always use for " + dlg.mime + " files"
                    color: Theme.fg1
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                    elide: Text.ElideRight
                }
                MSwitch {
                    checked: dlg.makeDefault
                    onToggled: dlg.makeDefault = !dlg.makeDefault
                }
            }
        }
    }
}
