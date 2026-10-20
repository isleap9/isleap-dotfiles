pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU, memory, temperature, GPU, disk and network numbers for the dashboard.
// Only polls while the dashboard is open.
Singleton {
    id: root

    readonly property bool active: Globals.dashboardOpen
    readonly property int historyLength: 30

    // CPU
    property real cpu: 0                 // 0–100
    property var cpuHistory: []
    property real cpuTemp: -1            // °C, -1 = unknown
    property string cpuName: ""
    // Memory (bytes)
    property real memTotal: 0
    property real memUsed: 0
    property var memHistory: []
    readonly property real memPercent: memTotal > 0 ? memUsed / memTotal * 100 : 0
    // GPU (NVIDIA via nvidia-smi)
    property bool gpuAvailable: false
    property string gpuName: ""
    property real gpu: 0
    property real gpuTemp: -1
    property real vramUsed: 0            // MiB
    property real vramTotal: 0
    property var gpuHistory: []
    // Disk (root filesystem, bytes)
    property real diskTotal: 0
    property real diskUsed: 0
    readonly property real diskPercent: diskTotal > 0 ? diskUsed / diskTotal * 100 : 0
    // Network (bytes per second, all interfaces but loopback)
    property real netDown: 0
    property real netUp: 0
    property var netHistory: []
    // Uptime (seconds)
    property real uptime: 0

    function push(list, value) {
        const l = [...list, value];
        return l.length > historyLength ? l.slice(l.length - historyLength) : l;
    }

    function bytes(b, digits) {
        const units = ["B", "KB", "MB", "GB", "TB"];
        let i = 0;
        while (b >= 1024 && i < units.length - 1) { b /= 1024; i++; }
        return b.toFixed(i === 0 ? 0 : digits ?? 1) + " " + units[i];
    }
    function rate(b) { return bytes(b, 1) + "/s"; }

    function duration(s) {
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
        if (d > 0) return `${d}d ${h}h`;
        if (h > 0) return `${h}h ${m}m`;
        return `${m}m`;
    }

    // ── CPU (/proc/stat) ──
    property var lastCpu: null
    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + (f[4] ?? 0);
            const total = f.reduce((a, b) => a + b, 0);
            if (root.lastCpu) {
                const dt = total - root.lastCpu.total;
                const di = idle - root.lastCpu.idle;
                if (dt > 0) {
                    root.cpu = Math.max(0, Math.min(100, (1 - di / dt) * 100));
                    root.cpuHistory = root.push(root.cpuHistory, root.cpu);
                }
            }
            root.lastCpu = { total, idle };
        }
    }

    // ── Memory (/proc/meminfo) ──
    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const get = k => Number((text().match(new RegExp("^" + k + ":\\s+(\\d+)", "m")) ?? [])[1] ?? 0) * 1024;
            root.memTotal = get("MemTotal");
            root.memUsed = root.memTotal - get("MemAvailable");
            root.memHistory = root.push(root.memHistory, root.memPercent);
        }
    }

    // ── Network (/proc/net/dev) ──
    property var lastNet: null
    FileView {
        id: netdev
        path: "/proc/net/dev"
        onLoaded: {
            let rx = 0, tx = 0;
            for (const line of text().split("\n").slice(2)) {
                const [name, rest] = line.split(":");
                if (!rest || name.trim() === "lo") continue;
                const f = rest.trim().split(/\s+/).map(Number);
                rx += f[0];
                tx += f[8];
            }
            const now = Date.now();
            if (root.lastNet) {
                const dt = (now - root.lastNet.time) / 1000;
                if (dt > 0) {
                    root.netDown = Math.max(0, (rx - root.lastNet.rx) / dt);
                    root.netUp = Math.max(0, (tx - root.lastNet.tx) / dt);
                    root.netHistory = root.push(root.netHistory, root.netDown);
                }
            }
            root.lastNet = { rx, tx, time: now };
        }
    }

    // ── Uptime ──
    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: root.uptime = Number(text().split(" ")[0])
    }

    // ── CPU temperature: k10temp (AMD), coretemp (Intel) or zenpower ──
    property string tempPath: ""
    Process {
        running: true
        command: ["sh", "-c", "for d in /sys/class/hwmon/hwmon*; do case \"$(cat $d/name)\" in k10temp|coretemp|zenpower) echo $d/temp1_input; exit;; esac; done; true"]
        stdout: StdioCollector { onStreamFinished: root.tempPath = text.trim() }
    }
    Process {
        running: true
        command: ["sh", "-c", "grep -m1 'model name' /proc/cpuinfo | cut -d: -f2"]
        stdout: StdioCollector { onStreamFinished: root.cpuName = text.trim().replace(/\s+\d+-Core Processor$/, "").replace(/\(R\)|\(TM\)/g, "") }
    }
    FileView {
        id: tempFile
        path: root.tempPath
        onLoaded: root.cpuTemp = Number(text()) / 1000
    }

    // ── GPU ──
    Process {
        id: gpuProc
        command: ["nvidia-smi", "--query-gpu=name,utilization.gpu,temperature.gpu,memory.used,memory.total", "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",").map(s => s.trim());
                if (f.length < 5) return;
                root.gpuAvailable = true;
                root.gpuName = f[0].replace(/^NVIDIA\s+/, "");
                root.gpu = Number(f[1]);
                root.gpuTemp = Number(f[2]);
                root.vramUsed = Number(f[3]);
                root.vramTotal = Number(f[4]);
                root.gpuHistory = root.push(root.gpuHistory, root.gpu);
            }
        }
    }

    // ── Disk ──
    Process {
        id: diskProc
        command: ["df", "-B1", "--output=size,used", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split("\n")[1]?.trim().split(/\s+/).map(Number) ?? [];
                if (f.length < 2) return;
                root.diskTotal = f[0];
                root.diskUsed = f[1];
            }
        }
    }

    property int tick: 0
    Timer {
        interval: 1000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            netdev.reload();
            uptimeFile.reload();
            if (root.tempPath) tempFile.reload();
            if (root.tick % 2 === 0 && !gpuProc.running) gpuProc.running = true;
            if (root.tick % 30 === 0 && !diskProc.running) diskProc.running = true;
            root.tick++;
        }
    }
}
