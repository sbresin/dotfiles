#!/usr/bin/env bash
# Pre-cache DDC/CI brightness values for external monitors.
# Listens for ddcutil-service ConnectedDisplaysChanged signals and refreshes
# the brightness cache so that the first keypress is fast (no GetVcp needed).
#
# Runs as a long-lived process via Hyprland exec-once.
# Power-efficient: blocks on D-Bus socket, zero CPU while idle.

set -euo pipefail

SERVICE='com.ddcutil.DdcutilService'
OBJECT='/com/ddcutil/DdcutilObject'
IFACE='com.ddcutil.DdcutilInterface'

CACHE_DIR="/run/user/$(id -u)/brightness"
DEBOUNCE_SECONDS=2
VCP_BRIGHTNESS=16

mkdir -p "$CACHE_DIR"

# ── Resolve monitor identity from ListDetected ──
# Populates parallel arrays: DISPLAY_NUMS, MONITOR_IDS
resolve_monitors() {
    DISPLAY_NUMS=()
    MONITOR_IDS=()

    local raw_json

    # Try JSON output first, fall back to plain text + regex
    if raw_json=$(busctl --user --json=short call "$SERVICE" "$OBJECT" "$IFACE" \
            ListDetected u 0 2>/dev/null); then
        local count
        count=$(printf '%s' "$raw_json" | jq '.data[1] | length')

        for ((i = 0; i < count; i++)); do
            local display_num serial bin_serial edid_txt mid=""
            display_num=$(printf '%s' "$raw_json" | jq -r ".data[1][$i][0]")
            serial=$(printf '%s' "$raw_json" | jq -r ".data[1][$i][5]")
            bin_serial=$(printf '%s' "$raw_json" | jq -r ".data[1][$i][8]")
            edid_txt=$(printf '%s' "$raw_json" | jq -r ".data[1][$i][7]")

            if [[ -n "$serial" && "$serial" != "null" && "$serial" != "" ]]; then
                mid="$serial"
            elif [[ -n "$bin_serial" && "$bin_serial" != "null" && "$bin_serial" != "0" ]]; then
                mid="bin_${bin_serial}"
            elif [[ -n "$edid_txt" && "$edid_txt" != "null" ]]; then
                mid="edid_$(printf '%s' "$edid_txt" | sha256sum | cut -d' ' -f1)"
            fi

            if [[ -n "$mid" ]]; then
                DISPLAY_NUMS+=("$display_num")
                MONITOR_IDS+=("$mid")
            fi
        done
    else
        # Fallback: plain text output + regex
        local raw_text
        raw_text=$(busctl --user call "$SERVICE" "$OBJECT" "$IFACE" \
            ListDetected u 0 2>/dev/null) || return 1

        if [[ "$raw_text" =~ ia\ \(iiisssqsu\)\ ([0-9]+)\ ([0-9]+)\ ([0-9]+)\ \"([^\"]*)\"\ \"([^\"]*)\"\ \"([^\"]*)\"\ ([0-9]+)\ \"([^\"]*)\"\ ([0-9]+) ]]; then
            local display_num="${BASH_REMATCH[1]}"
            local serial="${BASH_REMATCH[6]}"
            local bin_serial="${BASH_REMATCH[9]}"
            local edid_txt="${BASH_REMATCH[8]}"
            local mid=""

            if [[ -n "$serial" ]]; then
                mid="$serial"
            elif [[ "$bin_serial" != "0" ]]; then
                mid="bin_${bin_serial}"
            elif [[ -n "$edid_txt" ]]; then
                mid="edid_$(printf '%s' "$edid_txt" | sha256sum | cut -d' ' -f1)"
            fi

            if [[ -n "$mid" ]]; then
                DISPLAY_NUMS+=("$display_num")
                MONITOR_IDS+=("$mid")
            fi
        fi
    fi
}

# ── Refresh cache for all detected external monitors ──
refresh_all() {
    resolve_monitors

    for ((i = 0; i < ${#MONITOR_IDS[@]}; i++)); do
        local monitor_id="${MONITOR_IDS[$i]}"
        local display_num="${DISPLAY_NUMS[$i]}"
        local cache_file="$CACHE_DIR/${monitor_id}.state"

        # Query brightness via GetVcp
        local result
        result=$(busctl --user call "$SERVICE" "$OBJECT" "$IFACE" \
            GetVcp isyu "$display_num" "" "$VCP_BRIGHTNESS" 0 2>/dev/null) || continue

        if [[ "$result" =~ ^qqsis[[:space:]]+([0-9]+)[[:space:]]+([0-9]+) ]]; then
            local value="${BASH_REMATCH[1]}"
            local max="${BASH_REMATCH[2]}"

            cat > "$cache_file" <<EOF
cached_value=$value
cached_max=$max
cached_updated_at=$(date +%s)
cached_pending_delta=0
cached_pending_until=0
cached_display_num=$display_num
cached_vcp=$VCP_BRIGHTNESS
EOF
        fi
    done
}

# ── Initial refresh for already-connected displays ──
refresh_all

# ── Listen for connect/disconnect signals with debounce ──
DEBOUNCE_FILE="$CACHE_DIR/.debounce_ts"
echo "0" > "$DEBOUNCE_FILE"

busctl --user monitor --match \
    "type='signal',interface='$IFACE',member='ConnectedDisplaysChanged'" 2>/dev/null |
while read -r line; do
    # busctl monitor emits multiple lines per signal; trigger on the signal header
    if [[ "$line" == *"ConnectedDisplaysChanged"* ]]; then
        # Debounce: write current timestamp to file, then spawn a worker
        # that sleeps and only fires if the timestamp hasn't moved.
        signal_time=$(date +%s)
        echo "$signal_time" > "$DEBOUNCE_FILE"
        (
            sleep "$DEBOUNCE_SECONDS"
            stored=$(cat "$DEBOUNCE_FILE" 2>/dev/null || echo "0")
            # Only refresh if no newer signal overwrote the timestamp
            if [[ "$stored" == "$signal_time" ]]; then
                refresh_all
            fi
        ) &
    fi
done
