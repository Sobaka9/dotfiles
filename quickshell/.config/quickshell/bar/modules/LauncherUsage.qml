// How often each application has been launched, so the list can lead with the
// ones actually used.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
    readonly property string statePath: stateDir + "/quickshell-launcher-usage"

    // id -> launch count
    property var counts: ({})

    function countFor(id) {
        return root.counts[id] || 0;
    }

    function record(id) {
        if (!id) return;
        const next = Object.assign({}, root.counts);
        next[id] = (next[id] || 0) + 1;
        root.counts = next;
        store.setText(root.serialise());
    }

    function serialise() {
        let out = "";
        for (const id in root.counts)
            out += root.counts[id] + "\t" + id + "\n";
        return out;
    }

    Component.onCompleted: {
        const mine = root.parseOwn(store.text());
        if (Object.keys(mine).length > 0) {
            root.counts = mine;
            return;
        }
        // Nothing of ours yet: take wofi's history as a starting point.
        const seeded = root.parseWofi(wofi.text());
        if (Object.keys(seeded).length > 0) {
            root.counts = seeded;
            store.setText(root.serialise());
        }
    }

    function parseOwn(text) {
        const map = {};
        for (const line of (text || "").split("\n")) {
            const t = line.trim();
            if (t.length === 0) continue;
            const sep = t.indexOf("\t");
            if (sep < 0) continue;
            const n = parseInt(t.slice(0, sep));
            if (!isNaN(n)) map[t.slice(sep + 1)] = n;
        }
        return map;
    }

    function parseWofi(text) {
        const map = {};
        for (const line of (text || "").split("\n")) {
            const t = line.trim();
            if (t.length === 0) continue;
            const sp = t.indexOf(" ");
            if (sp < 0) continue;
            const n = parseInt(t.slice(0, sp));
            const file = t.slice(sp + 1);
            // ".../code.desktop" -> "code", which is the entry id.
            const base = file.slice(file.lastIndexOf("/") + 1).replace(/\.desktop$/, "");
            if (!isNaN(n) && base.length > 0)
                map[base] = Math.max(map[base] || 0, n);
        }
        return map;
    }

    FileView {
        id: store
        path: root.statePath
        blockLoading: true
        printErrors: false
        atomicWrites: true
    }

    FileView {
        id: wofi
        path: Quickshell.env("HOME") + "/.cache/wofi-drun"
        blockLoading: true
        printErrors: false
    }
}
