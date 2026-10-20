import QtQuick
import Quickshell
import qs
import qs.components

// Weather: the same Open-Meteo data as the dashboard (WeatherData), so they always match.
// Click: the dashboard's Weather tab. Right click: wttr.in in the browser. Hover: summary.
Pill {
    id: root

    readonly property var w: WeatherData.current
    property var screen: null

    readonly property string summary: {
        if (!WeatherData.ready || !w) return "";
        const d = WeatherData.daily;
        const lines = [
            `${WeatherData.place}`,
            `${WeatherData.describe(w.code)}, feels like ${WeatherData.temp(w.feels)}`,
            `Humidity ${Math.round(w.humidity)}% · Wind ${Math.round(w.wind)} ${WeatherData.windUnit}`,
            ""
        ];
        d.slice(0, 3).forEach((day, i) => lines.push(
            `${i === 0 ? "Today" : i === 1 ? "Tomorrow" : Qt.formatDate(day.date, "dddd")}: `
            + `${WeatherData.temp(day.max)} / ${WeatherData.temp(day.min)}, ${WeatherData.describe(day.code)}, rain ${day.rain}%`));
        return lines.join("\n");
    }

    shown: WeatherData.ready
    onClicked: m => {
        if (m.button === Qt.RightButton)
            Quickshell.execDetached(["xdg-open", "https://wttr.in/" + encodeURIComponent(Config.bar.weatherCity)]);
        else
            Globals.toggleDashboard("weather", screen);
    }

    BarText { icon: true; text: WeatherData.icon(root.w?.code, root.w?.isDay) }
    BarText { text: Math.round(root.w?.temp ?? 0) + WeatherData.tempUnit }

    // Hover: now + the next 3 days (Material card)
    Tooltip {
        target: root
        show: (root.hovered || Globals.hoverPreview === "weather") && WeatherData.ready && !Globals.dashboardOpen

        Column {
            spacing: 12
            Row {
                spacing: 14
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: WeatherData.icon(root.w?.code, root.w?.isDay)
                    color: Theme.accent
                    font.family: Theme.iconFont
                    font.variableAxes: Theme.iconAxes
                    font.pixelSize: 44
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: `${WeatherData.temp(root.w?.temp)}  ${WeatherData.describe(root.w?.code)}`
                        color: Theme.fg1
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 3
                        font.weight: Font.Bold
                    }
                    Text {
                        text: `Feels like ${WeatherData.temp(root.w?.feels)} · ${WeatherData.place}`
                        color: Theme.fg2
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 3
                    }
                    Row {
                        spacing: 4
                        Text { text: "humidity_percentage"; color: Theme.fg2; font.family: Theme.iconFont; font.variableAxes: Theme.iconAxes; font.pixelSize: Theme.fontSize; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: `${Math.round(root.w?.humidity ?? 0)}%`; color: Theme.fg2; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3; anchors.verticalCenter: parent.verticalCenter }
                        Item { width: 8; height: 1 }
                        Text { text: "air"; color: Theme.fg2; font.family: Theme.iconFont; font.variableAxes: Theme.iconAxes; font.pixelSize: Theme.fontSize; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: `${Math.round(root.w?.wind ?? 0)} ${WeatherData.windUnit}`; color: Theme.fg2; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
            Row {
                spacing: 8
                Repeater {
                    model: WeatherData.daily.slice(0, 4)
                    Rectangle {
                        required property var modelData
                        required property int index
                        width: 74
                        height: 88
                        radius: 16
                        color: index === 0 ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16) : BarConfig.surface(Theme.bg2)
                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: parent.parent.index === 0 ? "Today" : Qt.formatDate(parent.parent.modelData.date, "ddd")
                                color: parent.parent.index === 0 ? Theme.accent : Theme.fg1
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 3
                                font.weight: Font.Bold
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: WeatherData.icon(parent.parent.modelData.code, true)
                                color: Theme.fg1
                                font.family: Theme.iconFont
                                font.variableAxes: Theme.iconAxes
                                font.pixelSize: 24
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: `${WeatherData.temp(parent.parent.modelData.max)} ${WeatherData.temp(parent.parent.modelData.min)}`
                                color: Theme.fg1
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 4
                                font.weight: Font.Bold
                            }
                        }
                    }
                }
            }
        }
    }
}
