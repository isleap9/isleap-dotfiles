import QtQuick
import QtQuick.Layouts
import qs

// Weather: now, next 24 hours (chart), 7 days, and details (humidity, wind, UV…).
Item {
    id: root

    readonly property var w: WeatherData.current
    readonly property var today: WeatherData.daily[0] ?? null
    readonly property bool h24: Config.bar.clock24h

    implicitWidth: 6 * 128 + 5 * 8
    implicitHeight: column.implicitHeight

    function hour(d) { return Qt.formatTime(d, h24 ? "HH:mm" : "h AP"); }
    function clock(d) { return Qt.formatTime(d, h24 ? "HH:mm" : "h:mm AP"); }

    // Not loaded yet / error
    DashCard {
        visible: !WeatherData.ready
        anchors.fill: parent
        Column {
            anchors.centerIn: parent
            spacing: 12
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: WeatherData.loading ? "Loading the forecast…" : (WeatherData.error || "No weather yet")
                color: Theme.fg2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.weight: Font.Bold
            }
            DashButton { anchors.horizontalCenter: parent.horizontalCenter; icon: "\u{F0450}"; onClicked: WeatherData.refresh() }
        }
    }

    ColumnLayout {
        id: column
        visible: WeatherData.ready
        width: parent.width
        spacing: 8

        // ── Now ──
        DashCard {
            Layout.fillWidth: true
            implicitHeight: 150

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                spacing: 20

                Text {
                    text: WeatherData.icon(root.w?.code, root.w?.isDay)
                    color: Theme.accent
                    font.family: Theme.iconFont
                    font.pixelSize: 96
                }
                ColumnLayout {
                    spacing: 0
                    Text {
                        text: WeatherData.temp(root.w?.temp)
                        color: Theme.fg1
                        font.family: Theme.font
                        font.pixelSize: 64
                        font.weight: Font.Bold
                    }
                    Text {
                        text: `Feels like ${WeatherData.temp(root.w?.feels)}`
                        color: Theme.fg2
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        Layout.fillWidth: true
                        text: WeatherData.describe(root.w?.code)
                        elide: Text.ElideRight
                        color: Theme.fg1
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 6
                        font.weight: Font.Bold
                    }
                    Text {
                        Layout.fillWidth: true
                        text: `\u{F034E} ${WeatherData.place}`
                        elide: Text.ElideRight
                        color: Theme.fg2
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                    }
                    Text {
                        text: `H ${WeatherData.temp(root.today?.max)}   L ${WeatherData.temp(root.today?.min)}`
                        color: Theme.fg1
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                        font.weight: Font.Bold
                    }
                }
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    spacing: 6
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: 0
                        UnitButton { unit: "metric"; label: "°C" }
                        UnitButton { unit: "imperial"; label: "°F" }
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: 4
                        Text {
                            text: "Updated " + Qt.formatTime(WeatherData.updated, root.h24 ? "HH:mm" : "h:mm AP")
                            color: Theme.fg2
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 4
                        }
                        DashButton {
                            size: 28
                            icon: "\u{F0450}"
                            enabled: !WeatherData.loading
                            onClicked: WeatherData.refresh()
                        }
                    }
                }
            }
        }

        // ── Next 24 hours ──
        DashCard {
            Layout.fillWidth: true
            implicitHeight: 170
            title: "Next 24 hours"
            icon: "\u{F0954}"

            Item {
                id: chart
                anchors.fill: parent
                readonly property var hours: WeatherData.hourly
                readonly property real minT: Math.min(...hours.map(h => h.temp))
                readonly property real maxT: Math.max(...hours.map(h => h.temp))
                readonly property real step: hours.length > 1 ? width / hours.length : width
                readonly property real plotTop: 22
                readonly property real plotBottom: height - 44
                function yFor(t) { return maxT === minT ? (plotTop + plotBottom) / 2 : plotBottom - (t - minT) / (maxT - minT) * (plotBottom - plotTop); }

                // Rain chance bars
                Repeater {
                    model: chart.hours
                    Rectangle {
                        required property var modelData
                        required property int index
                        x: index * chart.step + chart.step * 0.2
                        width: chart.step * 0.6
                        height: (chart.plotBottom - chart.plotTop) * modelData.rain / 100 * 0.6
                        y: chart.plotBottom - height
                        radius: 3
                        color: Theme.blue
                        opacity: 0.35
                    }
                }

                Canvas {
                    anchors.fill: parent
                    property var data: chart.hours
                    property color line: Theme.accent
                    onDataChanged: requestPaint()
                    onLineChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const h = chart.hours;
                        if (h.length < 2) return;
                        const px = i => i * chart.step + chart.step / 2;
                        ctx.beginPath();
                        ctx.moveTo(px(0), chart.yFor(h[0].temp));
                        for (let i = 1; i < h.length; i++) {
                            const x0 = px(i - 1), x1 = px(i);
                            ctx.bezierCurveTo((x0 + x1) / 2, chart.yFor(h[i - 1].temp), (x0 + x1) / 2, chart.yFor(h[i].temp), x1, chart.yFor(h[i].temp));
                        }
                        ctx.lineWidth = 3;
                        ctx.strokeStyle = line;
                        ctx.stroke();
                        ctx.lineTo(px(h.length - 1), chart.plotBottom);
                        ctx.lineTo(px(0), chart.plotBottom);
                        ctx.closePath();
                        const g = ctx.createLinearGradient(0, chart.plotTop, 0, chart.plotBottom);
                        g.addColorStop(0, Qt.rgba(line.r, line.g, line.b, 0.25));
                        g.addColorStop(1, Qt.rgba(line.r, line.g, line.b, 0));
                        ctx.fillStyle = g;
                        ctx.fill();
                    }
                }

                // Every 3 hours: temperature above the line, icon and time below
                Repeater {
                    model: chart.hours.length
                    Item {
                        id: mark
                        required property int index
                        readonly property var h: chart.hours[index]
                        visible: index % 3 === 0
                        x: index * chart.step + chart.step / 2
                        Rectangle {
                            x: -4
                            y: chart.yFor(mark.h.temp) - 4
                            width: 8; height: 8; radius: 4
                            color: Theme.accent
                            border.width: 2
                            border.color: Theme.bg1
                        }
                        Text {
                            x: -width / 2
                            y: chart.yFor(mark.h.temp) - 24
                            text: WeatherData.temp(mark.h.temp)
                            color: Theme.fg1
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 3
                            font.weight: Font.Bold
                        }
                        Text {
                            x: -width / 2
                            y: chart.plotBottom + 4
                            text: WeatherData.icon(mark.h.code, mark.h.isDay)
                            color: Theme.fg1
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.fontSize + 2
                        }
                        Text {
                            x: -width / 2
                            y: chart.plotBottom + 24
                            text: mark.index === 0 ? "Now" : root.hour(mark.h.time)
                            color: Theme.fg2
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 4
                        }
                    }
                }
            }
        }

        // ── 7 days ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: WeatherData.daily
                DashCard {
                    id: day
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: 120
                    color: index === 0 ? Theme.bg2 : Theme.bg1

                    Column {
                        anchors.centerIn: parent
                        spacing: 3
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: day.index === 0 ? "Today" : Qt.formatDate(day.modelData.date, "ddd")
                            color: day.index === 0 ? Theme.accent : Theme.fg1
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                            font.weight: Font.Bold
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: WeatherData.icon(day.modelData.code, true)
                            color: Theme.fg1
                            font.family: Theme.iconFont
                            font.pixelSize: 28
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: `${WeatherData.temp(day.modelData.max)} / ${WeatherData.temp(day.modelData.min)}`
                            color: Theme.fg1
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 3
                            font.weight: Font.Bold
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: `\u{F058C} ${day.modelData.rain}%`
                            color: day.modelData.rain >= 50 ? Theme.blue : Theme.fg2
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 4
                        }
                    }
                }
            }
        }

        // ── Details ──
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            rowSpacing: 8
            columnSpacing: 8

            Detail { icon: "\u{F058E}"; label: "Humidity"; value: Math.round(root.w?.humidity ?? 0) + "%" }
            Detail {
                icon: "\u{F059D}"; label: "Wind"
                value: `${Math.round(root.w?.wind ?? 0)} ${WeatherData.windUnit}`
                extra: WeatherData.compass(root.w?.windDir ?? 0)
                arrow: root.w?.windDir ?? -1
            }
            Detail { icon: "\u{F029A}"; label: "Pressure"; value: Math.round(root.w?.pressure ?? 0) + " hPa" }
            Detail {
                icon: "\u{F0F2F}"; label: "UV index"
                readonly property real uv: root.today?.uv ?? root.w?.uv ?? 0
                value: uv.toFixed(0)
                extra: uv < 3 ? "Low" : uv < 6 ? "Moderate" : uv < 8 ? "High" : uv < 11 ? "Very high" : "Extreme"
            }
            Detail {
                icon: "\u{F0208}"; label: "Visibility"
                value: WeatherData.imperial ? ((root.w?.visibility ?? 0) / 5280).toFixed(1) + " mi" : ((root.w?.visibility ?? 0) / 1000).toFixed(1) + " km"
            }
            Detail { icon: "\u{F0590}"; label: "Clouds"; value: Math.round(root.w?.clouds ?? 0) + "%" }
            Detail { icon: "\u{F059C}"; label: "Sunrise"; value: root.today ? root.clock(root.today.sunrise) : "--" }
            Detail { icon: "\u{F059B}"; label: "Sunset"; value: root.today ? root.clock(root.today.sunset) : "--" }
        }
    }

    component Detail: DashCard {
        id: d
        property string label
        property string value
        property string extra: ""
        property real arrow: -1          // wind direction, degrees (where it comes from)
        icon: ""
        Layout.fillWidth: true
        implicitHeight: 78

        RowLayout {
            anchors.fill: parent
            spacing: 12
            Text {
                text: d.icon
                color: Theme.accent
                font.family: Theme.iconFont
                font.pixelSize: 26
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    Layout.fillWidth: true
                    text: d.label
                    elide: Text.ElideRight
                    color: Theme.fg2
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 3
                    font.weight: Font.Bold
                }
                RowLayout {
                    spacing: 6
                    Text {
                        text: d.value
                        color: Theme.fg1
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 2
                        font.weight: Font.Bold
                    }
                    Text {
                        visible: d.arrow >= 0
                        // Arrow points where the wind blows to
                        text: "\u{F005D}"
                        rotation: d.arrow + 180
                        color: Theme.fg1
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.fontSize
                    }
                    Text {
                        visible: d.extra !== ""
                        text: d.extra
                        color: Theme.fg2
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 3
                    }
                }
            }
        }
    }

    component UnitButton: Rectangle {
        id: ub
        property string unit
        property string label
        readonly property bool current: Config.dashboard.units === unit
        implicitWidth: 40
        implicitHeight: 28
        radius: 14
        color: current ? Theme.accent : ubArea.containsMouse ? Theme.bg3 : Theme.bg2
        Text {
            anchors.centerIn: parent
            text: ub.label
            color: ub.current ? Theme.bg0 : Theme.fg1
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 3
            font.weight: Font.Bold
        }
        MouseArea {
            id: ubArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Config.dashboard.units = ub.unit
        }
    }
}
