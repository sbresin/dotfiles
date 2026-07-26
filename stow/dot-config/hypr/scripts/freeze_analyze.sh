#!/usr/bin/env bash
# Analyze system logs around a freeze event.
#
# Usage:
#   freeze_analyze.sh              # Analyze the most recent freeze event
#   freeze_analyze.sh <timestamp>  # Analyze a specific event (ISO-8601 or unix timestamp)
#   freeze_analyze.sh --list       # List all logged freeze events

set -euo pipefail

LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/freeze-debug"
LOG_FILE="$LOG_DIR/events.log"

if [[ ! -f "$LOG_FILE" ]]; then
    echo "No freeze events logged yet."
    echo "Press SUPER+SHIFT+F when you observe a freeze to log an event."
    exit 1
fi

# List mode
if [[ "${1:-}" == "--list" || "${1:-}" == "-l" ]]; then
    echo "Logged freeze events:"
    echo "====================="
    grep "^timestamp:" "$LOG_FILE" | sed 's/timestamp: //'
    exit 0
fi

# Get timestamp to analyze
if [[ -n "${1:-}" ]]; then
    TIMESTAMP="$1"
else
    # Get most recent event
    TIMESTAMP=$(grep "^timestamp:" "$LOG_FILE" | tail -1 | sed 's/timestamp: //')
    if [[ -z "$TIMESTAMP" ]]; then
        echo "No freeze events found in log."
        exit 1
    fi
fi

echo "Analyzing freeze event at: $TIMESTAMP"
echo ""

# Show the logged state from that event
echo "=== Logged State ==="
# Blocks are variable-length (connector/backlight/monitor counts vary), so
# extract from the "--- FREEZE EVENT ---" header of the matching block through
# its closing "---" marker, rather than a fixed line count.
awk -v ts="timestamp: $TIMESTAMP" '
    /^--- FREEZE EVENT ---$/ { block = $0 "\n"; found = 0; next }
    { block = block $0 "\n" }
    $0 == ts { found = 1 }
    /^---$/ && found { printf "%s", block; exit }
' "$LOG_FILE"
echo ""

# Calculate time window (30 seconds before, 2 minutes after)
# Handle both ISO-8601 and unix timestamps
if [[ "$TIMESTAMP" =~ ^[0-9]+$ ]]; then
    SINCE=$(date --date="@$((TIMESTAMP - 30))" --iso-8601=seconds)
    UNTIL=$(date --date="@$((TIMESTAMP + 120))" --iso-8601=seconds)
else
    SINCE=$(date --date="$TIMESTAMP - 30 seconds" --iso-8601=seconds)
    UNTIL=$(date --date="$TIMESTAMP + 2 minutes" --iso-8601=seconds)
fi

echo "=== Kernel Messages ($SINCE to $UNTIL) ==="
journalctl -k --since "$SINCE" --until "$UNTIL" --no-pager 2>/dev/null || echo "(no kernel messages or permission denied)"
echo ""

echo "=== DRM/GPU Related Messages ==="
journalctl -k --since "$SINCE" --until "$UNTIL" --no-pager 2>/dev/null | grep -iE 'drm|amdgpu|gpu|psr|edp|display|panel|flip|vblank|timeout|hang|reset|error|fail' || echo "(none found)"
echo ""

echo "=== Power Management Messages ==="
journalctl --since "$SINCE" --until "$UNTIL" --no-pager 2>/dev/null | grep -iE 'suspend|resume|sleep|power|battery|charging|tlp|pm:' || echo "(none found)"
echo ""

echo "=== Hyprland Messages ==="
journalctl --user --since "$SINCE" --until "$UNTIL" --no-pager 2>/dev/null | grep -iE 'hyprland|hypr' | head -30 || echo "(none found)"
echo ""

echo "=== Tips ==="
echo "- If no errors appear, the freeze may be silent (PSR/power state issue)"
echo "- Look for 'timeout', 'hang', 'reset', 'error' in the kernel messages"
echo "- 'PM: parent ... should not be sleeping' indicates power management race"
echo "- To test PSR disable: add 'amdgpu.dcdebugmask=0x10' to kernel params"
