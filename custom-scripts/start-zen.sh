#!/bin/bash
# Launch Zen and put its restored windows on the right workspaces.
# Windows are placed in the order Zen restores them (Hyprland's client list order).
workspaces=(2 5)

zen-browser "$@" &

zen_windows() { hyprctl clients -j | jq -r '.[] | select(.class == "zen") | .address'; }

# Wait up to 15s for windows to appear, then until the count stops changing for 1s.
last=0 stable=0
for _ in $(seq 150); do
    count=$(zen_windows | wc -l)
    if (( count > 0 && count == last )); then
        (( ++stable >= 10 )) && break
    else
        stable=0
    fi
    last=$count
    sleep 0.1
done

i=0
for addr in $(zen_windows); do
    ws=${workspaces[i]:-${workspaces[-1]}}
    hyprctl dispatch "hl.dsp.window.move({ workspace = \"$ws\", follow = false, window = \"address:$addr\" })" >/dev/null
    ((i++))
done
