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
                        text: "check"
                        color: card.modelData.colors[2] ?? Theme.accent
                        font.family: Theme.iconFont
                        font.variableAxes: Theme.iconAxes
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
                ? "Used for all text" : "Not installed — pick another font"
            Dropdown {
                searchable: true
                placeholder: "Search fonts"
                current: Config.appearance.font
                // Every installed font, each drawn in itself. Icon / emoji fonts are left out, and
                // the many Noto fonts for specific scripts only show up when you search.
                options: {
                    const skip = /^(Material Symbols|Font Awesome|Noto Color Emoji|Noto Music|Symbols Nerd Font)/;
                    const core = /^Noto (Sans|Serif|Sans Mono|Serif Display|Sans Display)$/;
                    return Qt.fontFamilies()
                        .filter((f, i, all) => all.indexOf(f) === i && !skip.test(f) && !f.startsWith("."))
                        .sort((a, b) => a.localeCompare(b))
                        .map(f => ({ value: f, label: f, font: f, hidden: f.startsWith("Noto ") && !core.test(f) }));
                }
                onSelected: v => Config.appearance.font = v
            }
        }
        Option {
            label: "Icon style"
            description: "Google's Material Symbols, used for every icon in the shell"
            Dropdown {
                current: Theme.iconFont
                options: [
                    { value: "Material Symbols Rounded", label: "Rounded", description: "Soft corners (default)", preview: "Material Symbols Rounded" },
                    { value: "Material Symbols Outlined", label: "Outlined", description: "Classic Material look", preview: "Material Symbols Outlined" },
                    { value: "Material Symbols Sharp", label: "Sharp", description: "Square corners", preview: "Material Symbols Sharp" }
                ].filter(o => Qt.fontFamilies().includes(o.value))
                onSelected: v => Config.appearance.iconFont = v
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
