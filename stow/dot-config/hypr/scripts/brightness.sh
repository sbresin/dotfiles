#!/usr/bin/env bash
# Context-aware brightness/contrast control.
# Acts on the screen where the currently focused window lives.
# Internal screens use brightnessctl, external screens use ddcutil-service via D-Bus.
#
# Features (external monitors):
#   - Per-monitor cache keyed by serial/EDID (in /run/user/$UID/brightness/)
#   - Rapid keypresses batched into a single SetVcp call (150ms window)
#   - GetVcp only called when cache is stale (>6h) or missing
#
# Usage:
#   brightness.sh brightness up
#   brightness.sh brightness down
#   brightness.sh contrast up
#   brightness.sh contrast down

set -euo pipefail

PROPERTY="${1:?Usage: brightness.sh <brightness|contrast> <up|down>}"
DIRECTION="${2:?Usage: brightness.sh <brightness|contrast> <up|down>}"
STEP_INTERNAL=5
STEP_EXTERNAL=10
BATCH_WINDOW_MS=150
STALE_SECONDS=$((6 * 3600)) # 6 hours

SERVICE='com.ddcutil.DdcutilService'
OBJECT='/com/ddcutil/DdcutilObject'
IFACE='com.ddcutil.DdcutilInterface'

CACHE_DIR="/run/user/$(id -u)/brightness"

# Get the Hyprland monitor name for the focused workspace
MONITOR=$(hyprctl activeworkspace -j | jq -r '.monitor')

# Check if this monitor has a backlight device (internal screen).
# The sysfs symlink for a backlight includes the DRM connector name,
# e.g. .../card1-eDP-1/amdgpu_bl1, so we match the monitor name in the path.
BACKLIGHT_DEV=""
for bl in /sys/class/backlight/*/; do
    [ -d "$bl" ] || continue
    link=$(readlink -f "$bl")
    if [[ "$link" == *"$MONITOR"* ]]; then
        BACKLIGHT_DEV=$(basename "$bl")
        break
    fi
done

if [[ -n "$BACKLIGHT_DEV" ]]; then
    # ── Internal screen: use brightnessctl ──
    if [[ "$PROPERTY" == "contrast" ]]; then
        exit 0 # contrast not supported on internal panel
    fi
    case "$DIRECTION" in
        up) brightnessctl -d "$BACKLIGHT_DEV" -e4 -n2 set "${STEP_INTERNAL}%+" ;;
        down) brightnessctl -d "$BACKLIGHT_DEV" -e4 -n2 set "${STEP_INTERNAL}%-" ;;
    esac
    exit 0
fi

# ── External screen: use ddcutil-service via D-Bus with caching + batching ──

case "$PROPERTY" in
    brightness) VCP=16 ;; # 0x10
    contrast) VCP=18 ;;   # 0x12
esac

now_s() { date +%s; }
now_ms() { date +%s%3N; }

# ── Resolve monitor identity and display number via ListDetected ──
# Returns: MONITOR_ID and DISPLAY_NUM
resolve_monitor() {
    local raw_json display_num serial bin_serial edid_txt

    # Try JSON output first, fall back to plain text + regex
    if raw_json=$(busctl --user --json=short call "$SERVICE" "$OBJECT" "$IFACE" \
            ListDetected u 0 2>/dev/null); then
        # JSON path: parse with jq
        # The data array contains structs; each struct has fields in order:
        #   display_number, usb_bus, usb_device, manufacturer_id, model_name,
        #   serial_number, product_code, edid_txt, binary_serial_number
        # busctl --json=short wraps the return in {"type":"...","data":[...]}
        # The struct fields are nested arrays inside the data array.

        local count
        count=$(printf '%s' "$raw_json" | jq '.data[1] | length')

        for ((i = 0; i < count; i++)); do
            display_num=$(printf '%s' "$raw_json" | jq -r ".data[1][$i][0]")
            serial=$(printf '%s' "$raw_json" | jq -r ".data[1][$i][5]")
            bin_serial=$(printf '%s' "$raw_json" | jq -r ".data[1][$i][8]")
            edid_txt=$(printf '%s' "$raw_json" | jq -r ".data[1][$i][7]")

            local mid=""
            if [[ -n "$serial" && "$serial" != "null" && "$serial" != "" ]]; then
                mid="$serial"
            elif [[ -n "$bin_serial" && "$bin_serial" != "null" && "$bin_serial" != "0" ]]; then
                mid="bin_${bin_serial}"
            elif [[ -n "$edid_txt" && "$edid_txt" != "null" ]]; then
                mid="edid_$(printf '%s' "$edid_txt" | sha256sum | cut -d' ' -f1)"
            fi

            if [[ -n "$mid" ]]; then
                MONITOR_ID="$mid"
                DISPLAY_NUM="$display_num"
                return 0
            fi
        done
    else
        # Fallback: plain text output + regex
        local raw_text
        raw_text=$(busctl --user call "$SERVICE" "$OBJECT" "$IFACE" \
            ListDetected u 0 2>/dev/null) || return 1

        # Extract display_number (first integer after the array header),
        # serial_number, and binary_serial_number using regex on the flat output.
        # Format: i <count> ... i <display_num> i <usb_bus> i <usb_device>
        #         s "<mfr>" s "<model>" s "<serial>" q <product_code>
        #         s "<edid>" u <bin_serial> ...

        # Extract first display's fields
        if [[ "$raw_text" =~ ia\ \(iiisssqsu\)\ ([0-9]+)\ ([0-9]+)\ ([0-9]+)\ \"([^\"]*)\"\ \"([^\"]*)\"\ \"([^\"]*)\"\ ([0-9]+)\ \"([^\"]*)\"\ ([0-9]+) ]]; then
            display_num="${BASH_REMATCH[1]}"
            serial="${BASH_REMATCH[6]}"
            bin_serial="${BASH_REMATCH[9]}"
            edid_txt="${BASH_REMATCH[8]}"

            local mid=""
            if [[ -n "$serial" ]]; then
                mid="$serial"
            elif [[ "$bin_serial" != "0" ]]; then
                mid="bin_${bin_serial}"
            elif [[ -n "$edid_txt" ]]; then
                mid="edid_$(printf '%s' "$edid_txt" | sha256sum | cut -d' ' -f1)"
            fi

            if [[ -n "$mid" ]]; then
                MONITOR_ID="$mid"
                DISPLAY_NUM="$display_num"
                return 0
            fi
        fi
    fi

    return 1
}

# ── Cache helpers ──

cache_file() { echo "$CACHE_DIR/${MONITOR_ID}.state"; }
lock_file() { echo "$CACHE_DIR/${MONITOR_ID}.lock"; }
flush_lock_file() { echo "$CACHE_DIR/${MONITOR_ID}.flush.lock"; }

load_cache() {
    local f
    f=$(cache_file)
    if [[ -f "$f" ]]; then
        # shellcheck source=/dev/null
        source "$f"
    else
        cached_value=""
        cached_max=""
        cached_updated_at=0
        cached_pending_delta=0
        cached_pending_until=0
        cached_display_num=""
        cached_vcp=""
    fi
}

save_cache() {
    cat > "$(cache_file)" <<EOF
cached_value=$cached_value
cached_max=$cached_max
cached_updated_at=$cached_updated_at
cached_pending_delta=$cached_pending_delta
cached_pending_until=$cached_pending_until
cached_display_num=$cached_display_num
cached_vcp=$cached_vcp
EOF
}

refresh_from_ddc() {
    local result
    result=$(busctl --user call "$SERVICE" "$OBJECT" "$IFACE" \
        GetVcp isyu "$DISPLAY_NUM" "" "$VCP" 0 2>/dev/null) || return 1

    if [[ "$result" =~ ^qqsis[[:space:]]+([0-9]+)[[:space:]]+([0-9]+) ]]; then
        cached_value="${BASH_REMATCH[1]}"
        cached_max="${BASH_REMATCH[2]}"
        cached_updated_at=$(now_s)
        cached_display_num="$DISPLAY_NUM"
        cached_vcp="$VCP"
        return 0
    fi
    return 1
}

# ── Flush worker: applies accumulated delta as a single SetVcp ──

flush_worker() {
    # Sleep until the batch window expires, then apply
    while true; do
        sleep "$(awk "BEGIN {printf \"%.3f\", $BATCH_WINDOW_MS / 1000}")"

        # Lock and check if there's still pending work
        (
            flock 9

            load_cache

            now=$(now_ms)

            # If deadline moved (more keypresses came in), loop again
            if [[ "$cached_pending_until" -gt "$now" ]]; then
                exit 100 # signal to outer loop: re-sleep
            fi

            # Nothing pending
            if [[ "$cached_pending_delta" -eq 0 ]]; then
                exit 0
            fi

            # Compute new value
            new_val=$((cached_value + cached_pending_delta))
            ((new_val < 0)) && new_val=0
            ((new_val > cached_max)) && new_val="$cached_max"

            # Apply single SetVcp
            busctl --user call "$SERVICE" "$OBJECT" "$IFACE" \
                SetVcp isyqu "$cached_display_num" "" "$cached_vcp" "$new_val" 4 \
                >/dev/null 2>&1

            # Update cache
            cached_value="$new_val"
            cached_updated_at=$(now_s)
            cached_pending_delta=0
            cached_pending_until=0
            save_cache

        ) 9>"$(lock_file)"

        local rc=$?
        if [[ "$rc" -eq 100 ]]; then
            continue # re-sleep, deadline moved
        fi
        break
    done
}

# ── Main: accumulate delta + spawn flush ──

mkdir -p "$CACHE_DIR"

# Resolve monitor identity
MONITOR_ID=""
DISPLAY_NUM=""
resolve_monitor || { exit 1; }

# Accumulate delta under lock
(
    flock 9

    load_cache

    # Refresh from DDC if cache is stale, missing, or VCP changed
    now_sec=$(now_s)
    if [[ -z "$cached_value" || -z "$cached_max" \
       || "$cached_vcp" != "$VCP" \
       || $((now_sec - cached_updated_at)) -gt $STALE_SECONDS ]]; then
        refresh_from_ddc || exit 1
    fi

    # Compute delta for this keypress
    delta=$((cached_max * STEP_EXTERNAL / 100))
    case "$DIRECTION" in
        up) cached_pending_delta=$((cached_pending_delta + delta)) ;;
        down) cached_pending_delta=$((cached_pending_delta - delta)) ;;
    esac

    cached_pending_until=$(( $(now_ms) + BATCH_WINDOW_MS ))
    cached_display_num="$DISPLAY_NUM"
    cached_vcp="$VCP"
    save_cache

) 9>"$(lock_file)" || exit 1

# Spawn flush worker in background (only one at a time via flush lock)
(
    flock -n 9 || exit 0 # another flush worker is already running
    flush_worker
) 9>"$(flush_lock_file)" &
disown $!
