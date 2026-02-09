#!/usr/bin/env bash

# --- Configuration ---
INTERNAL_MONITOR="eDP-1"

# --- Check States ---

# 1. Check Lid State
# grep -q is silent; returns 0 if match found (Open), 1 otherwise (Closed)
if grep -q "open" /proc/acpi/button/lid/LID0/state; then
	LID_OPEN=true
else
	LID_OPEN=false
fi

# 2. Check External Monitor
# Any monitor that is not the internal eDP panel counts as external.
# This catches DP-*, HDMI-*, etc.
EXTERNAL_PRESENT=false
while IFS= read -r line; do
	if [[ "$line" =~ ^Monitor\ (.+)\ \(ID ]]; then
		[[ "${BASH_REMATCH[1]}" != "$INTERNAL_MONITOR" ]] && EXTERNAL_PRESENT=true && break
	fi
done < <(hyprctl monitors)

# --- Logic Implementation ---

# Rule 2: External screen is NOT there -> ALWAYS enable internal
if [ "$EXTERNAL_PRESENT" = false ]; then
	TARGET="enable"

# Rule 1: External screen is there, lid open -> Enable internal
elif [ "$LID_OPEN" = true ]; then
	TARGET="enable"

# Rule 3: External screen is there, lid closed -> Disable internal
else
	TARGET="disable"
fi

# --- Apply Changes ---

if [ "$TARGET" = "enable" ]; then
	# Only apply if not already enabled (optional optimization, but hyprctl is fast)
	hyprctl keyword monitor "$INTERNAL_MONITOR, preferred, auto, auto"
	echo "Enabling Internal Monitor" # Debug
else
	hyprctl keyword monitor "$INTERNAL_MONITOR, disabled"
	echo "Disabling Internal Monitor" # Debug
fi
