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

    Tooltip {
        target: root
        show: root.hovered && root.summary !== "" && !Globals.dashboardOpen
        text: root.summary
    }
}
