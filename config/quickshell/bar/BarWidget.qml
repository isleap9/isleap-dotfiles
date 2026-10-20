import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

// One widget on the bar, created from its entry in the lane config: { type: "clock", ...options }
Loader {
    id: root

    required property var widget
    required property var barWindow
    property bool flat: false

    readonly property var components: ({
        arch: arch, weather: weather, clock: clock, cava: cava, media: media, workspaces: workspaces,
        tray: tray, language: language, volume: volume, network: network, notifications: notifications,
        power: power, controlcenter: controlcenter, settings: settingsButton, screenshot: screenshot, spacer: spacer
    })

    sourceComponent: components[widget?.type] ?? null
    // Collapse when the widget has nothing to show (e.g. media with nothing playing)
    visible: item?.shown ?? false
    Layout.alignment: Qt.AlignVCenter

    Component { id: arch; ArchButton { settings: root.widget; flat: root.flat } }
    Component { id: weather; Weather { settings: root.widget; flat: root.flat; screen: root.barWindow.screen } }
    Component { id: clock; Clock { settings: root.widget; flat: root.flat; screen: root.barWindow.screen } }
    Component { id: cava; Cava { settings: root.widget; flat: root.flat } }
    Component { id: media; Media { settings: root.widget; flat: root.flat; screen: root.barWindow.screen } }
    Component { id: workspaces; Workspaces { settings: root.widget; flat: root.flat; screen: root.barWindow.screen } }
    Component { id: tray; Tray { settings: root.widget; flat: root.flat; barWindow: root.barWindow } }
    Component { id: language; Language { settings: root.widget; flat: root.flat } }
    Component { id: volume; Volume { settings: root.widget; flat: root.flat } }
    Component { id: network; Network { settings: root.widget; flat: root.flat } }
    Component { id: notifications; NotifButton { settings: root.widget; flat: root.flat } }
    Component { id: power; PowerButton { settings: root.widget; flat: root.flat } }
    Component { id: controlcenter; ControlCenterButton { settings: root.widget; flat: root.flat } }
    Component { id: settingsButton; SettingsButton { settings: root.widget; flat: root.flat } }
    Component { id: screenshot; ScreenshotButton { settings: root.widget; flat: root.flat } }
    Component { id: spacer; Spacer { settings: root.widget } }
}
