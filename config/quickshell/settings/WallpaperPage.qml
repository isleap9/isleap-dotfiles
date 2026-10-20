import QtQuick
import QtQuick.Layouts
import qs

Page {
    id: page

    Section {
        title: "Wallpaper"
        Option {
            icon: "wallpaper"
            label: "Wallpaper picker"
            description: "Browse ~/Pictures/Wallpapers or search Wallhaven (SUPER+SHIFT+W)"
            PillButton {
                text: "Open picker"
                primary: true
                onClicked: Globals.run("~/.config/quickshell/scripts/wallpaper-picker.sh")
            }
        }
    }

    Section {
        title: "Dynamic colors"
        description: "Generate the color theme from your wallpaper (matugen)"

        Option {
            icon: "contrast"
            label: "Use wallpaper colors"
            description: "When on, picking a wallpaper recolors everything"
            Toggle { checked: DynamicTheme.enabled; onToggled: DynamicTheme.setEnabled(!DynamicTheme.enabled) }
        }
        Option {
            icon: "clear_night"
            label: "Mode"
            Segmented {
                options: [["dark", "Dark"], ["light", "Light"]]
                current: DynamicTheme.mode
                onSelected: v => DynamicTheme.setMode(v)
            }
        }
        Option {
            icon: "refresh"
            label: "Apply to current wallpaper"
            description: "Regenerate colors now"
            PillButton { text: "Apply"; onClicked: DynamicTheme.applyNow() }
        }
    }

    Section {
        title: "Color scheme"
        description: "How matugen turns the wallpaper into colors"

        GridLayout {
            Layout.fillWidth: true
            Layout.margins: 10
            columns: Math.max(2, Math.floor(width / 220))
            rowSpacing: 6
            columnSpacing: 6

            Repeater {
                model: DynamicTheme.schemes
                Rectangle {
                    id: chip
                    required property var modelData
                    readonly property bool active: modelData[0] === DynamicTheme.scheme
                    Layout.fillWidth: true
                    implicitHeight: 52
                    radius: 14
                    color: active ? Theme.accent : area.containsMouse ? Theme.bg3 : Theme.bg2
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 14
                        Text {
                            text: chip.modelData[0].replace("scheme-", "").replace("-", " ")
                            color: chip.active ? Theme.bg1 : Theme.fg1
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                            font.weight: Font.Bold
                            font.capitalization: Font.Capitalize
                        }
                        Text {
                            text: chip.modelData[1]
                            color: chip.active ? Theme.bg1 : Theme.fg2
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 3
                        }
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: DynamicTheme.setScheme(chip.modelData[0])
                    }
                }
            }
        }
    }

    Component.onCompleted: DynamicTheme.refresh()
}
