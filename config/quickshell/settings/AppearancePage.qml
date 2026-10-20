import QtQuick
import QtQuick.Layouts
import qs

Page {
    id: page

    Section {
        title: "Theme"
        description: Themes.current === "dynamic.css"
            ? "Using colors from your wallpaper (Dynamic theme). Pick a theme to switch back."
            : "Applies to the bar, popups, kitty, Hyprland borders, btop and KDE apps."

        GridLayout {
            Layout.fillWidth: true
            Layout.margins: 10
            columns: Math.max(2, Math.floor(width / 190))
            rowSpacing: 8
            columnSpacing: 8

            Repeater {
                model: Themes.list

                Rectangle {
                    id: card
                    required property var modelData
                    readonly property bool active: modelData.file === Themes.current

                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 14
                    color: modelData.colors[0] ?? Theme.bg2
                    border.width: active ? 3 : 1
                    border.color: active ? Theme.accent : area.containsMouse ? Theme.fg2 : Theme.bg3

                    Text {
                        x: 12; y: 10
                        width: parent.width - 24
                        text: card.modelData.name
                        color: card.modelData.colors[1] ?? Theme.fg1
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }
                    Row {
                        x: 12
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 10
                        spacing: 4
                        Repeater {
                            model: card.modelData.colors.slice(2)
                            Rectangle {
                                required property string modelData
                                width: 18; height: 18; radius: 9
                                color: modelData
                            }
                        }
                    }
                    Text {
                        visible: card.active
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 10
                        text: "󰄬"
                        color: card.modelData.colors[2] ?? Theme.accent
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.fontSize + 4
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Themes.apply(card.modelData.key)
                    }
                }
            }
        }
    }

    Section {
        title: "Text"

        Option {
            label: "Font"
            description: Qt.fontFamilies().includes(Config.appearance.font)
                ? "Used for all text" : "Font not found — check the name"
            TextBox {
                text: Config.appearance.font
                valid: Qt.fontFamilies().includes(text)
                onAccepted: v => Config.appearance.font = v
            }
        }
        Option {
            label: "Icon font"
            description: "A Nerd Font, used for icons"
            TextBox {
                text: Config.appearance.iconFont
                valid: Qt.fontFamilies().includes(text)
                onAccepted: v => Config.appearance.iconFont = v
            }
        }
        Option {
            label: "Font size"
            Stepper {
                value: Config.appearance.fontSize
                from: 10; to: 24
                suffix: " px"
                onChanged: v => Config.appearance.fontSize = v
            }
        }
    }

    Section {
        title: "Motion"
        Option {
            label: "Animations"
            description: "Speed of bar and popup animations"
            Segmented {
                options: [[0, "Off"], [0.5, "Fast"], [1, "Normal"], [2, "Slow"]]
                current: Config.appearance.animationSpeed
                onSelected: v => Config.appearance.animationSpeed = v
            }
        }
    }

    Component.onCompleted: Themes.refresh()
}
