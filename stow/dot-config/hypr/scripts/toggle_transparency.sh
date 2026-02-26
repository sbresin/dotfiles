#!/usr/bin/env bash

# Toggle transparency and blur globally.
# Uses a named windowrule (no-transparency) to force terminal windows opaque
# (ghostty, foot, wezterm), and disables blur to eliminate compositor overhead.

STATE_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr-transparency-off"

if [ -f "$STATE_FILE" ]; then
	hyprctl keyword 'windowrule[no-transparency]:enable false'
	hyprctl keyword decoration:blur:enabled true
	rm "$STATE_FILE"
else
	hyprctl keyword 'windowrule[no-transparency]:enable true'
	hyprctl keyword decoration:blur:enabled false
	touch "$STATE_FILE"
fi
