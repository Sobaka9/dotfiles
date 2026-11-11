#!/bin/bash
# Gracefully quit Zen (Ctrl+Q, so the session is saved) before powering off/rebooting.
# Usage: power.sh poweroff|reboot

action="$1"
[[ "$action" == "poweroff" || "$action" == "reboot" ]] || { echo "usage: $0 poweroff|reboot" >&2; exit 1; }

zen_open() { hyprctl clients -j | jq -e 'any(.[]; .class == "zen")' >/dev/null; }

if zen_open; then
    hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "CTRL", key = "Q", window = "class:^(zen)$" })'
    # Wait up to 10s for Zen's windows to close (session is saved by then);
    # systemd takes care of the lingering process cleanup.
    for _ in $(seq 100); do
        zen_open || break
        sleep 0.1
    done
fi

if command -v hyprshutdown >/dev/null; then
    hyprshutdown -p "systemctl $action"
else
    systemctl "$action"
fi
