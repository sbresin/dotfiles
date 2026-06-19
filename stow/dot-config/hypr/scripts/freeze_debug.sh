#!/usr/bin/env bash
# Log a timestamp marker when display freeze is observed.
# Press the keybind when you notice a freeze, then analyze logs after recovery.
#
# Usage: After freeze recovery, run:
#   ~/.config/hypr/scripts/freeze_analyze.sh [timestamp]
# or manually:
#   journalctl -k --since "TIMESTAMP" --until "+2min"

set -euo pipefail

LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/freeze-debug"
LOG_FILE="$LOG_DIR/events.log"

mkdir -p "$LOG_DIR"

TIMESTAMP=$(date --iso-8601=seconds)
TIMESTAMP_UNIX=$(date +%s)

# Also capture quick non-root state info inline
AC_STATUS=$(cat /sys/class/power_supply/ACAD/online 2>/dev/null || echo "?")
BAT_STATUS=$(cat /sys/class/power_supply/BAT1/status 2>/dev/null || echo "unknown")
BAT_CAPACITY=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo "?")
GPU_POWER=$(cat /sys/class/drm/card1/device/power_state 2>/dev/null || echo "unknown")
GPU_RUNTIME=$(cat /sys/class/drm/card1/device/power/runtime_status 2>/dev/null || echo "unknown")
EDP_STATUS=$(cat /sys/class/drm/card1-eDP-1/enabled 2>/dev/null || echo "unknown")

cat >> "$LOG_FILE" <<EOF
--- FREEZE EVENT ---
timestamp: $TIMESTAMP
timestamp_unix: $TIMESTAMP_UNIX
ac_online: $AC_STATUS
battery_status: $BAT_STATUS
battery_capacity: $BAT_CAPACITY%
gpu_power_state: $GPU_POWER
gpu_runtime_status: $GPU_RUNTIME
edp_enabled: $EDP_STATUS
---
EOF

# Log to stderr as well (visible in journalctl --user)
echo "Logged freeze event at $TIMESTAMP" >&2
