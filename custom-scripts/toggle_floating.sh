#!/bin/bash

# Get the floating status of the active window
# Returns "true" if floating, "false" if tiled
is_floating=$(hyprctl activewindow -j | jq -r '.floating')

if [[ "$is_floating" == "false" ]]; then
    # Window is currently TILED.
    hyprctl dispatch 'hl.dsp.window.float({ action = "toggle" })'
    read -r w h < <(hyprctl monitors -j | jq -r '.[] | select(.focused) | "\(.width / .scale * 0.75 | floor) \(.height / .scale * 0.75 | floor)"')
    hyprctl dispatch "hl.dsp.window.resize({ x = $w, y = $h, relative = false })"
    hyprctl dispatch 'hl.dsp.window.center()'
else
    # Window is currently FLOATING.
    # Just tile it back.
    hyprctl dispatch 'hl.dsp.window.float({ action = "toggle" })'
fi