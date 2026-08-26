#!/bin/bash

# This script sets wallpapers for two screens and then monitors the
# linux-wallpaperengine process for high memory usage, restarting it if necessary.
#
# Usage:
# ./script_name.sh <path_for_DP-2> <path_for_HDMI-A-3> <true|false>

# --- Configuration ---
# The memory usage limit in percent. If the process exceeds this, it will be restarted.
MEMORY_LIMIT="10.0"
# How many seconds to wait between memory checks.
CHECK_INTERVAL=60

# --- Argument Validation ---
if [ "$#" -ne 3 ]; then
    echo "❌ Error: Invalid number of arguments."
    echo "Usage: $0 <path_for_DP-2> <path_for_HDMI-A-3> <true|false>"
    exit 1
fi

# --- Variable Assignment ---
DP3_WALLPAPER="$1"
DP2_WALLPAPER="$2"
USE_NO_PAUSE_ARG="$3"
PAUSE_FLAG=""

if [ "$USE_NO_PAUSE_ARG" == "true" ]; then
    PAUSE_FLAG="--no-fullscreen-pause"
fi

# --- Command & Path Definitions ---
EXECUTABLE="/opt/linux-wallpaperengine/"
PROCESS_NAME="linux-wallpaperengine"

cd $EXECUTABLE

export LD_LIBRARY_PATH=".:$LD_LIBRARY_PATH"

CMD=(
    ./linux-wallpaperengine
    --silent
    $PAUSE_FLAG
    --screen-root DP-3 --bg "$DP3_WALLPAPER"
    --screen-root DP-2 --bg "$DP2_WALLPAPER"
)
--
echo "Killing any existing instances of $PROCESS_NAME..."
killall $PROCESS_NAME &>/dev/null
sleep 1

echo "🚀 Starting wallpaper engine..."
"${CMD[@]}" &

echo "✅ Wallpapers set successfully. Now monitoring memory usage..."

while :
do
    sleep $CHECK_INTERVAL

    PID=$(pgrep -f "$PROCESS_NAME")

    if [ -z "$PID" ]; then
        echo "🤔 Process '$PROCESS_NAME' is not running. Exiting monitor."
        exit 0
    fi

    # Get the memory usage percentage.
    MEM_USAGE=$(ps u -p $PID | awk 'NR>1 {print $4}')

    if [ -z "$MEM_USAGE" ]; then
        continue
    fi

    IS_OVER_LIMIT=$(awk -v mu="$MEM_USAGE" -v ml="$MEMORY_LIMIT" 'BEGIN {print (mu > ml)}')

    if [ "$IS_OVER_LIMIT" -eq 1 ]; then
        echo "⚠️ Memory usage ($MEM_USAGE%) is over the ${MEMORY_LIMIT}% limit. Restarting..."
        
        killall $PROCESS_NAME
        sleep 2
        "${CMD[@]}" &
        echo "✅ Process restarted successfully."
    fi
done
