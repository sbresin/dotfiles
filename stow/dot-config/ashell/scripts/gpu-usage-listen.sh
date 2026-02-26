#!/usr/bin/env bash

set -euo pipefail

interval="${ASHELL_GPU_POLL_INTERVAL:-2}"
gpu_busy_path=""

for candidate in /sys/class/drm/card*/device/gpu_busy_percent; do
    if [[ -r "$candidate" ]]; then
        gpu_busy_path="$candidate"
        break
    fi
done

if [[ -z "$gpu_busy_path" ]]; then
    while true; do
        printf '{"text":"n/a","alt":"missing"}\n'
        sleep "$interval"
    done
fi

while true; do
    if read -r busy_raw < "$gpu_busy_path" && [[ "$busy_raw" =~ ^[0-9]+$ ]]; then
        state="ok"
        if ((busy_raw >= 80)); then
            state="hot"
        elif ((busy_raw >= 50)); then
            state="warn"
        fi

        printf '{"text":"%s%%","alt":"%s"}\n' "$busy_raw" "$state"
    else
        printf '{"text":"n/a","alt":"error"}\n'
    fi

    sleep "$interval"
done
