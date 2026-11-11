// Scoring for the launcher's search box.

pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    function norm(s) {
        return (s || "").toLowerCase().replace(/[^a-z0-9]/g, "");
    }

    // Letters of `q` appearing in `text` in order. Returns a score that
    // rewards matches packed close together, or -1 for no match.
    function subsequence(text, q) {
        let ti = 0;
        let first = -1;
        let last = -1;
        for (let qi = 0; qi < q.length; qi++) {
            const c = q[qi];
            let found = -1;
            while (ti < text.length) {
                if (text[ti] === c) { found = ti; ti++; break; }
                ti++;
            }
            if (found < 0) return -1;
            if (first < 0) first = found;
            last = found;
        }
        const span = last - first + 1;
        // A tight run beats letters scattered across the whole name.
        return Math.max(0, 100 - (span - q.length) * 4) + (first === 0 ? 30 : 0);
    }

    // First letters of each word: "Visual Studio Code" -> "vsc".
    function initials(name) {
        return (name || "").split(/[^A-Za-z0-9]+/)
            .filter(w => w.length > 0)
            .map(w => w[0].toLowerCase())
            .join("");
    }

    // Higher is better; -1 means the entry does not match at all.
    function score(entry, query) {
        const q = root.norm(query);
        if (q.length === 0) return 0;

        const name = root.norm(entry.name);
        const init = root.initials(entry.name);
        const generic = root.norm(entry.genericName);
        const comment = root.norm(entry.comment);
        const id = root.norm(entry.id);
        const exec = root.norm(entry.execString);

        if (name === q) return 1000;
        if (id === q) return 950;
        if (name.startsWith(q)) return 900 - (name.length - q.length);
        if (init === q) return 880;
        if (id.startsWith(q) || exec.startsWith(q)) return 850;
        if (init.startsWith(q)) return 820;
        if (name.includes(q)) return 700 - name.indexOf(q);

        const sub = root.subsequence(name, q);
        if (sub >= 0) return 400 + sub;

        const subId = root.subsequence(id + exec, q);
        if (subId >= 0) return 300 + subId;

        if (generic.includes(q)) return 250;
        if (comment.includes(q)) return 200;

        return -1;
    }
}
