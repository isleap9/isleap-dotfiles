import QtQuick
import QtQuick.Layouts
import qs

// Current weather. Click: the Weather tab.
DashCard {
    id: card

    readonly property var w: WeatherData.current
    readonly property var today: WeatherData.daily[0] ?? null
    readonly property bool big: width >= 260 || height >= 200

    clickable: true
    onClicked: Globals.dashboardTab = "weather"

    Text {
        visible: !WeatherData.ready
        anchors.centerIn: parent
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: WeatherData.error || "Loading…"
        color: Theme.fg2
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 3
    }

    // Small: icon + temperature, condition underneath
    ColumnLayout {
        visible: WeatherData.ready && !card.big
        anchors.centerIn: parent
        spacing: 0
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6
            Text {
                text: WeatherData.icon(card.w?.code, card.w?.isDay)
                color: Theme.accent
                font.family: Theme.iconFont
                font.variableAxes: Theme.iconAxes
                font.pixelSize: Math.min(34, card.height * 0.36)
            }
            Text {
                text: WeatherData.temp(card.w?.temp)
                color: Theme.fg1
                font.family: Theme.font
                font.pixelSize: Math.min(30, card.height * 0.32)
                font.weight: Font.Bold
            }
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: card.width - 16
            elide: Text.ElideRight
            text: WeatherData.describe(card.w?.code)
            color: Theme.fg2
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 3
            font.weight: Font.Bold
        }
    }

    // Big: plus place, high/low and feels like
    RowLayout {
        visible: WeatherData.ready && card.big
        anchors.fill: parent
        spacing: 14
        Text {
            text: WeatherData.icon(card.w?.code, card.w?.isDay)
            color: Theme.accent
            font.family: Theme.iconFont
            font.variableAxes: Theme.iconAxes
            font.pixelSize: Math.min(72, card.height * 0.55)
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                text: WeatherData.temp(card.w?.temp)
                color: Theme.fg1
                font.family: Theme.font
                font.pixelSize: Math.min(44, card.height * 0.36)
                font.weight: Font.Bold
            }
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: WeatherData.describe(card.w?.code)
                color: Theme.fg1
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                font.weight: Font.Bold
            }
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: `H ${WeatherData.temp(card.today?.max)}  L ${WeatherData.temp(card.today?.min)} · ${WeatherData.place}`
                color: Theme.fg2
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 3
            }
        }
    }
}
