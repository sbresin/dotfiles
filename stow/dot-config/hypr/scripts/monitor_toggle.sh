#!/usr/bin/env bash

# --- Configuration ---
INTERNAL_MONITOR="eDP-1"
# We specifically look for DP-[number] as requested, but you can change
# this regex to "DP-[0-9]+|HDMI-[A-Z0-9]+" to catch HDMI too.
EXTERNAL_MONITOR_REGEX="\sDP-[0-9]+"

# --- Check States ---

# 1. Check Lid State
# grep -q is silent; returns 0 if match found (Open), 1 otherwise (Closed)
if grep -q "open" /proc/acpi/button/lid/LID0/state; then
	LID_OPEN=true
else
	LID_OPEN=false
fi

# 2. Check External Monitor
# We use the regex against the output of hyprctl monitors
if [[ "$(hyprctl monitors)" =~ $EXTERNAL_MONITOR_REGEX ]]; then
	EXTERNAL_PRESENT=true
else
	EXTERNAL_PRESENT=false
fi

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
