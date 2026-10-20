import QtQuick
import QtQuick.Layouts
import qs

// Overview: cards on a 6-column grid (like DankMaterialShell's dashboard).
// Cards fill the grid in order, each in the first free spot that fits it.
// Edit mode: move cards earlier/later, change their width/height, remove them, add more.
Item {
    id: root

    property bool editMode: false

    readonly property int columns: 6
    readonly property int colWidth: 128
    readonly property int rowHeight: 96
    readonly property int gap: 8

    // All cards: name, icon, default size, and size limits
    readonly property var registry: ({
        clock:         { name: "Clock",         icon: "schedule", w: 2, h: 1, minW: 1, maxW: 4, minH: 1, maxH: 3, comp: clockComp },
        weather:       { name: "Weather",       icon: "partly_cloudy_day", w: 1, h: 1, minW: 1, maxW: 4, minH: 1, maxH: 3, comp: weatherComp },
        calendar:      { name: "Calendar",      icon: "calendar_month", w: 3, h: 3, minW: 2, maxW: 4, minH: 3, maxH: 5, comp: calendarComp },
        media:         { name: "Now playing",   icon: "music_note", w: 3, h: 1, minW: 2, maxW: 6, minH: 1, maxH: 4, comp: mediaComp },
        notifications: { name: "Notifications", icon: "notifications", w: 3, h: 5, minW: 2, maxW: 6, minH: 2, maxH: 8, comp: notifComp },
        user:          { name: "User",          icon: "person", w: 3, h: 1, minW: 2, maxW: 6, minH: 1, maxH: 1, comp: userComp },
        cpu:           { name: "CPU",           icon: "memory", w: 1, h: 1, minW: 1, maxW: 4, minH: 1, maxH: 3, comp: metricComp },
        memory:        { name: "Memory",        icon: "memory_alt", w: 1, h: 1, minW: 1, maxW: 4, minH: 1, maxH: 3, comp: metricComp },
        gpu:           { name: "GPU",           icon: "developer_board", w: 1, h: 1, minW: 1, maxW: 4, minH: 1, maxH: 3, comp: metricComp },
        disk:          { name: "Disk",          icon: "hard_drive", w: 1, h: 1, minW: 1, maxW: 4, minH: 1, maxH: 3, comp: metricComp },
        network:       { name: "Network",       icon: "lan", w: 1, h: 1, minW: 1, maxW: 4, minH: 1, maxH: 3, comp: metricComp }
    })
    readonly property var order: ["clock", "weather", "calendar", "media", "notifications", "user", "cpu", "memory", "gpu", "disk", "network"]

    // DMS's default layout
    readonly property var defaults: [
        { id: "clock", w: 2, h: 1 }, { id: "weather", w: 1, h: 1 }, { id: "notifications", w: 3, h: 5 },
        { id: "calendar", w: 3, h: 3 }, { id: "media", w: 3, h: 1 }
    ]
    // Saved lists come back from config.json as a list-like object, not a JS array: copy it
    readonly property var saved: Config.dashboard.cards ? Array.from(Config.dashboard.cards) : []
    readonly property var cards: (saved.length > 0 ? saved : defaults).filter(c => c && registry[c.id])

    // ── Layout: first free spot for each card, in order ──
    readonly property var layout: {
        const taken = [];
        const free = (x, y, w, h) => {
            for (let r = y; r < y + h; r++)
                for (let c = x; c < x + w; c++)
                    if (taken[r]?.[c]) return false;
            return true;
        };
        const spots = [];
        let rows = 0;
        for (const card of cards) {
            const w = Math.min(card.w, columns), h = card.h;
            let placed = null;
            for (let y = 0; !placed; y++)
                for (let x = 0; x <= columns - w && !placed; x++)
                    if (free(x, y, w, h)) placed = { x, y };
            for (let r = placed.y; r < placed.y + h; r++) {
                taken[r] = taken[r] ?? [];
                for (let c = placed.x; c < placed.x + w; c++) taken[r][c] = true;
            }
            spots.push({ x: placed.x, y: placed.y, w, h });
            rows = Math.max(rows, placed.y + h);
        }
        return { spots, rows: Math.max(rows, 1) };
    }
    readonly property int gridHeight: layout.rows * rowHeight + (layout.rows - 1) * gap

    implicitWidth: columns * colWidth + (columns - 1) * gap
    implicitHeight: gridHeight + (editMode ? addRow.implicitHeight + 16 : 0)

    // ── Editing ──
    function save(list) { Config.dashboard.cards = list; }
    function copy() { return JSON.parse(JSON.stringify(cards)); }
    function move(i, d) {
        const l = copy(), j = i + d;
        if (j < 0 || j >= l.length) return;
        [l[i], l[j]] = [l[j], l[i]];
        save(l);
    }
    function resize(i, dw, dh) {
        const l = copy(), r = registry[l[i].id];
        l[i].w = Math.max(r.minW, Math.min(r.maxW, l[i].w + dw));
        l[i].h = Math.max(r.minH, Math.min(r.maxH, l[i].h + dh));
        save(l);
    }
    // The last card can't go (an empty list means the default layout)
    function remove(i) { const l = copy(); if (l.length <= 1) return; l.splice(i, 1); save(l); }
    function add(id) { save([...copy(), { id, w: registry[id].w, h: registry[id].h }]); }

    Component { id: clockComp; ClockCard {} }
    Component { id: weatherComp; WeatherCard {} }
    Component { id: calendarComp; CalendarCard {} }
    Component { id: mediaComp; MediaCard {} }
    Component { id: notifComp; NotificationsCard {} }
    Component { id: userComp; UserCard {} }
    Component { id: metricComp; MetricCard { kind: parent?.cardId ?? "cpu" } }

    Repeater {
        model: root.cards.length

        Item {
            id: slot
            required property int index
            readonly property var card: root.cards[index]
            // While the list changes, a card can briefly have no spot yet
            readonly property var spot: root.layout.spots[index] ?? { x: 0, y: 0, w: 1, h: 1 }
            readonly property var info: root.registry[card?.id] ?? root.registry.clock
            readonly property string cardId: card?.id ?? ""

            x: spot.x * (root.colWidth + root.gap)
            y: spot.y * (root.rowHeight + root.gap)
            width: spot.w * root.colWidth + (spot.w - 1) * root.gap
            height: spot.h * root.rowHeight + (spot.h - 1) * root.gap
            Behavior on x { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }

            Loader {
                id: loader
                anchors.fill: parent
                readonly property string cardId: slot.cardId
                sourceComponent: slot.info.comp
                enabled: !root.editMode
            }

            // Edit controls on top of the card
            Rectangle {
                visible: root.editMode
                anchors.fill: parent
                radius: 18
                color: Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.82)
                border.width: 2
                border.color: Theme.accent

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 12
                    spacing: 4

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: `${slot.info.name}  ${slot.card?.w}×${slot.card?.h}`
                        elide: Text.ElideRight
                        color: Theme.fg1
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 3
                        font.weight: Font.Bold
                    }
                    Flow {
                        width: Math.min(parent.width, 7 * 30)
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2
                        DashButton { size: 28; icon: "chevron_left"; enabled: slot.index > 0; onClicked: root.move(slot.index, -1) }
                        DashButton { size: 28; icon: "chevron_right"; enabled: slot.index < root.cards.length - 1; onClicked: root.move(slot.index, 1) }
                        DashButton { size: 28; icon: "arrow_menu_close"; enabled: slot.card.w > slot.info.minW; onClicked: root.resize(slot.index, -1, 0) }
                        DashButton { size: 28; icon: "arrow_menu_open"; enabled: slot.card.w < slot.info.maxW; onClicked: root.resize(slot.index, 1, 0) }
                        DashButton { size: 28; icon: "unfold_less"; enabled: slot.card.h > slot.info.minH; onClicked: root.resize(slot.index, 0, -1) }
                        DashButton { size: 28; icon: "unfold_more"; enabled: slot.card.h < slot.info.maxH; onClicked: root.resize(slot.index, 0, 1) }
                        DashButton { size: 28; icon: "close"; onClicked: root.remove(slot.index) }
                    }
                }
            }
        }
    }

    // Add cards / reset (edit mode)
    Flow {
        id: addRow
        visible: root.editMode
        y: root.gridHeight + 16
        width: parent.width
        spacing: 6

        Repeater {
            model: root.order.filter(id => !root.cards.some(c => c.id === id))

            Chip {
                required property string modelData
                icon: "add  " + root.registry[modelData].icon
                text: root.registry[modelData].name
                onClicked: root.add(modelData)
            }
        }
        Chip {
            icon: "refresh"
            text: "Default layout"
            onClicked: Config.dashboard.cards = []
        }
    }

    component Chip: Rectangle {
        id: chip
        property string icon
        property string text
        signal clicked
        implicitWidth: chipRow.implicitWidth + 24
        implicitHeight: 32
        radius: 16
        color: chipArea.containsMouse ? Theme.accent : Theme.bg2
        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 8
            Text {
                text: chip.icon
                color: chipArea.containsMouse ? Theme.bg0 : Theme.fg1
                font.family: Theme.iconFont
                font.variableAxes: Theme.iconAxes
                font.pixelSize: Theme.fontSize
            }
            Text {
                text: chip.text
                color: chipArea.containsMouse ? Theme.bg0 : Theme.fg1
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
                font.weight: Font.Bold
            }
        }
        MouseArea {
            id: chipArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }
}
