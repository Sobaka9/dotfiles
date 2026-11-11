// Polls scripts/stats.sh and exposes the results as properties.

pragma Singleton
import QtQuick
import "root:/"
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int cpu: 0
    property int mem: 0
    property int temp: 0
    property bool online: true

    property int gpuTemp: 0
    property int gpuUtil: 0
    property int gpuMem: 0
    property int gpuMemTotal: 0
    // Bytes per second on the default route.
    property real rxRate: 0
    property real txRate: 0

    property int intervalMs: 2000

    Process {
        id: proc
        command: [Quickshell.shellDir + "/scripts/stats.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = this.text.trim().split(" ");
                if (f.length < 10) return;
                root.cpu = parseInt(f[0]);
                root.mem = parseInt(f[1]);
                root.temp = parseInt(f[2]);
                root.online = f[3] === "up";
                root.gpuTemp = parseInt(f[4]);
                root.gpuUtil = parseInt(f[5]);
                root.gpuMem = parseInt(f[6]);
                root.gpuMemTotal = parseInt(f[7]);
                root.rxRate = parseFloat(f[8]);
                root.txRate = parseFloat(f[9]);
            }
        }
    }

    // Skip a tick rather than stack processes if one is somehow still running.
    Timer {
        interval: root.intervalMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!proc.running) proc.running = true
    }
}
