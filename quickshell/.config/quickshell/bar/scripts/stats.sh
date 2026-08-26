#!/usr/bin/env bash
# One space-separated line of everything the bar polls:
#   <cpu%> <mem%> <cpuTempC> <net up|down> <gpuTempC> <gpu%> <gpuMemMiB> <gpuMemTotalMiB> <rxBytesPerSec> <txBytesPerSec>
#
# Kept as one script so the bar spawns one process per tick rather than one
# per reading. Audio is not here: it comes from Pipewire, which updates live.
set -uo pipefail

read_cpu() { awk '/^cpu /{t=$2+$3+$4+$5+$6+$7+$8; print t, t-$5}' /proc/stat; }

# CPU has to be sampled twice: /proc/stat holds totals since boot, not a rate.
read -r t1 b1 < <(read_cpu)
sleep 0.3
read -r t2 b2 < <(read_cpu)
cpu=$(awk -v dt="$((t2 - t1))" -v db="$((b2 - b1))" 'BEGIN { printf "%d", (dt > 0 ? db * 100 / dt : 0) }')

mem=$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END { printf "%d", (t - a) * 100 / t }' /proc/meminfo)

# thermal_zone2 is x86_pkg_temp, the same zone the waybar config used.
temp=$(awk '{ printf "%d", $1 / 1000 }' /sys/class/thermal/thermal_zone2/temp 2>/dev/null || echo 0)

if ip route get 1.1.1.1 >/dev/null 2>&1; then net=up; else net=down; fi

# GPU. Absent or broken driver just reports zeroes rather than failing the tick.
gpu_temp=0; gpu_util=0; gpu_mem=0; gpu_mem_total=0
if command -v nvidia-smi >/dev/null; then
    read -r gpu_temp gpu_util gpu_mem gpu_mem_total < <(
        nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,memory.used,memory.total \
                   --format=csv,noheader,nounits 2>/dev/null | tr -d ',' | head -1
    )
    : "${gpu_temp:=0}" "${gpu_util:=0}" "${gpu_mem:=0}" "${gpu_mem_total:=0}"
fi

# Network throughput. /proc/net/dev holds totals since boot, so the rate needs
# the previous sample; this script is re-run each tick, so it keeps that on disk.
iface=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
rx_rate=0; tx_rate=0
if [ -n "${iface:-}" ]; then
    read -r rx tx < <(awk -v i="${iface}:" '$1 == i { print $2, $10 }' /proc/net/dev)
    state="${XDG_RUNTIME_DIR:-/tmp}/qs-bar-net-${iface}"
    now=$(date +%s%3N)
    if [ -r "$state" ]; then
        read -r p_now p_rx p_tx < "$state"
        dt=$(( now - p_now ))
        # Skip nonsense: a counter reset, a stale sample, or a clock jump.
        if [ "$dt" -gt 0 ] && [ "$dt" -lt 30000 ] && [ "$rx" -ge "$p_rx" ] && [ "$tx" -ge "$p_tx" ]; then
            rx_rate=$(( (rx - p_rx) * 1000 / dt ))
            tx_rate=$(( (tx - p_tx) * 1000 / dt ))
        fi
    fi
    printf '%s %s %s\n' "$now" "$rx" "$tx" > "$state"
fi

echo "$cpu $mem $temp $net $gpu_temp $gpu_util $gpu_mem $gpu_mem_total $rx_rate $tx_rate"
