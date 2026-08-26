#!/bin/bash

# Configuration
MONITOR="DP-3"
# Resolution/Refresh must match your hyprland.conf exactly
MODE="2560x1440@240"
POS="1920x0"
SCALE="auto"

STATE_FILE="/tmp/hypr_hdr_state"

if [ -f "$STATE_FILE" ]; then
    # --- TURN HDR OFF ---
    notify-send -t 2000 "HDR Disabled" "Returning to 10-bit color"
    
    # 1. Reset monitor to standard 10-bit
    hyprctl keyword monitor "${MONITOR},${MODE},${POS},${SCALE}, bitdepth, 10"
    
    # 2. Clean up state file
    rm "$STATE_FILE"
    
    # 3. Reload gamma/colors (optional, helps if colors look washed out after)
    # hyprctl reload
else
    # --- TURN HDR ON ---
    notify-send -t 2000 "HDR Enabled" "Switching to 10-bit color"
    
    # 1. Set monitor to 10-bit depth (Required for HDR)
    # Syntax: monitor,resolution,position,scale,bitdepth,10
    hyprctl keyword monitor "${MONITOR},${MODE},${POS},${SCALE},bitdepth,10,cm,hdr,sdrbrightness,1.25,sdrsaturation,1.0"
    
    # 2. Create state file
    touch "$STATE_FILE"
fi