#!/usr/bin/env bash
# Log a timestamp marker + diagnostic snapshot when display freeze is observed
# or when an emergency display/UCSI keybind is invoked.
#
# Usage:
#   freeze_debug.sh [label]   # label defaults to "manual" (e.g. F, D-emergency, M-emergency)
#
# After freeze recovery, run:
#   ~/.config/hypr/scripts/freeze_analyze.sh [timestamp]
# or manually:
#   journalctl -k --since "TIMESTAMP" --until "+2min"

set -euo pipefail

LABEL="${1:-manual}"

LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/freeze-debug"
LOG_FILE="$LOG_DIR/events.log"

mkdir -p "$LOG_DIR"

TIMESTAMP=$(date --iso-8601=seconds)
TIMESTAMP_UNIX=$(date +%s)

# --- Power/battery state ---
AC_STATUS=$(cat /sys/class/power_supply/ACAD/online 2>/dev/null || echo "?")
BAT_STATUS=$(cat /sys/class/power_supply/BAT1/status 2>/dev/null || echo "unknown")
BAT_CAPACITY=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo "?")
GPU_POWER=$(cat /sys/class/drm/card1/device/power_state 2>/dev/null || echo "unknown")
GPU_RUNTIME=$(cat /sys/class/drm/card1/device/power/runtime_status 2>/dev/null || echo "unknown")
EDP_STATUS=$(cat /sys/class/drm/card1-eDP-1/enabled 2>/dev/null || echo "unknown")

# --- hyprctl monitors (name, disabled, dpms, mode, description) ---
# Compact one-line-per-monitor summary (avoids dumping the full pretty-printed
# JSON with availableModes etc. into the log).
MONITORS_SUMMARY=$(hyprctl monitors all -j 2>/dev/null |
    jq -c '.[] | {name, disabled, dpmsStatus, description, mode: "\(.width)x\(.height)@\(.refreshRate)"}' 2>/dev/null)
[[ -z "$MONITORS_SUMMARY" ]] && MONITORS_SUMMARY="(hyprctl/jq unavailable)"

# --- DRM connector states (all connectors, not just eDP) ---
CONNECTOR_STATE=""
for status_file in /sys/class/drm/card*-*/status; do
    [[ -e "$status_file" ]] || continue
    conn_dir=$(dirname "$status_file")
    conn_name=$(basename "$conn_dir")
    status=$(cat "$status_file" 2>/dev/null || echo "?")
    enabled=$(cat "$conn_dir/enabled" 2>/dev/null || echo "?")
    CONNECTOR_STATE+="  $conn_name: status=$status enabled=$enabled"$'\n'
done
[[ -z "$CONNECTOR_STATE" ]] && CONNECTOR_STATE="  (none found)"$'\n'

# --- Backlight state (all backlight devices) ---
BACKLIGHT_STATE=""
for bl_dir in /sys/class/backlight/*/; do
    [[ -d "$bl_dir" ]] || continue
    bl_name=$(basename "$bl_dir")
    brightness=$(cat "${bl_dir}brightness" 2>/dev/null || echo "?")
    max_brightness=$(cat "${bl_dir}max_brightness" 2>/dev/null || echo "?")
    BACKLIGHT_STATE+="  $bl_name: brightness=$brightness/$max_brightness"$'\n'
done
[[ -z "$BACKLIGHT_STATE" ]] && BACKLIGHT_STATE="  (none found)"$'\n'

# --- UCSI driver bind state (USB-C PD controller) ---
UCSI_STATE="unbound/absent"
for ucsi_dev in /sys/bus/platform/drivers/ucsi_acpi/USBC*; do
    [[ -e "$ucsi_dev" ]] || continue
    UCSI_STATE="bound: $(basename "$ucsi_dev")"
    break
done

{
    echo "--- FREEZE EVENT ---"
    echo "label: $LABEL"
    echo "timestamp: $TIMESTAMP"
    echo "timestamp_unix: $TIMESTAMP_UNIX"
    echo "ac_online: $AC_STATUS"
    echo "battery_status: $BAT_STATUS"
    echo "battery_capacity: $BAT_CAPACITY%"
    echo "gpu_power_state: $GPU_POWER"
    echo "gpu_runtime_status: $GPU_RUNTIME"
    echo "edp_enabled: $EDP_STATUS"
    echo "ucsi_state: $UCSI_STATE"
    echo "connector_states:"
    printf '%s' "$CONNECTOR_STATE"
    echo "backlight_states:"
    printf '%s' "$BACKLIGHT_STATE"
    echo "hyprctl_monitors:"
    echo "$MONITORS_SUMMARY" | sed 's/^/  /'
    echo "---"
} >> "$LOG_FILE"

# Log to stderr as well (visible in journalctl --user)
echo "Logged freeze event ($LABEL) at $TIMESTAMP" >&2
