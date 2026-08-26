#!/bin/bash

current_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

current_ws=$(hyprctl activeworkspace -j | jq '.id')

monitor_workspaces=($(hyprctl workspaces -j | jq -r --arg mon "$current_monitor" '.[] | select(.monitor == $mon) | .id' | sort -n))

current_idx=-1
for i in "${!monitor_workspaces[@]}"; do
    if [[ "${monitor_workspaces[$i]}" == "$current_ws" ]]; then
        current_idx=$i
        break
    fi
done

target_ws=$current_ws

if [[ "$1" == "next" ]]; then
    if [[ $current_idx -lt $((${#monitor_workspaces[@]} - 1)) ]]; then
        target_ws=${monitor_workspaces[$((current_idx + 1))]}
    fi
elif [[ "$1" == "prev" ]]; then
    if [[ $current_idx -gt 0 ]]; then
        target_ws=${monitor_workspaces[$((current_idx - 1))]}
    fi
fi

if [[ "$target_ws" != "$current_ws" ]]; then
    hyprctl dispatch "hl.dsp.focus({ workspace = \"$target_ws\" })"
fi