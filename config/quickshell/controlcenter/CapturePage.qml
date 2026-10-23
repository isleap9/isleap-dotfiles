import QtQuick
import qs

// Screenshots (hyprshot), screen recording (wf-recorder) and the color picker
MenuList {
    id: root

    property var cc   // set by the loader

    readonly property string out: "--output-folder ~/Pictures/Screenshots"

    readonly property var baseItems: [
        { icon: "screenshot_monitor", label: "Region", sub: "Select an area", run: `hyprshot -m region ${out}` },
        { icon: "monitor", label: "Fullscreen", sub: "Active monitor", run: `hyprshot -m output -m active ${out}` },
        { icon: "fit_screen", label: "Window", sub: "Click a window", run: `hyprshot -m window ${out}` },
        // $HOME instead of ~ because the path sits inside double quotes (no tilde expansion there)
        { icon: "screen_record", label: "Record screen", sub: "With audio", record: true,
            run: "wf-recorder -a -f \"$HOME/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4\"" },
        { icon: "crop_free", label: "Record region", sub: "Select an area, with audio", record: true,
            run: "wf-recorder -a -g \"$(slurp)\" -f \"$HOME/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4\"" },
        { icon: "colorize", label: "Color picker", sub: "Copy a color from the screen", run: "~/.config/hypr/scripts/color-picker.sh" }
    ]

    // A recording is running: offer to stop it above everything else
    items: Globals.recording
        ? [{ icon: "stop_circle", label: "Stop recording", sub: "Finish and save", run: "", stop: true }].concat(baseItems)
        : baseItems

    placeholder: "Search…"

    // Screenshots close the control center, then run. Starting a recording also flips
    // Globals.recording (so this page rebuilds with "Stop recording"); stopping finalizes the file.
    // Closing uses the same mechanism as cc.runAndClose: drop controlCenterOpen, then run.
    onActivated: item => {
        if (item.stop) {
            Globals.controlCenterOpen = false;
            Globals.stopRecording();
        } else if (item.record) {
            Globals.controlCenterOpen = false;
            Globals.startRecording("sleep 0.3; " + item.run);
        } else {
            cc.runAndClose("sleep 0.3; " + item.run);
        }
    }
    onBack: cc?.go("main")
}
