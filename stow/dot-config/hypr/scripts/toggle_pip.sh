#!/usr/bin/env bash

# Toggle picture-in-picture mode on the active window.
# Floats + pins the window, removes decorations, and moves it to the bottom-right corner.
# Running again on the same window reverses everything.

ACTIVE_WINDOW=$(hyprctl activewindow -j)
IS_FLOATING=$(echo "$ACTIVE_WINDOW" | jq -r '.floating')
IS_PINNED=$(echo "$ACTIVE_WINDOW" | jq -r '.pinned')

if [[ "$IS_FLOATING" == "true" && "$IS_PINNED" == "true" ]]; then
	# Undo PiP mode: restore decorations, unpin, unfloat
	hyprctl setprop active bordersize -1
	hyprctl setprop active no_blur -1
	hyprctl setprop active no_shadow -1
	hyprctl setprop active no_dim -1
	hyprctl dispatch pin active
	hyprctl dispatch togglefloating active
else
	# Enter PiP mode: float, pin, clean styling, move to bottom-right
	if [[ "$IS_FLOATING" != "true" ]]; then
		hyprctl dispatch togglefloating active
	fi
	hyprctl dispatch pin active
	hyprctl setprop active bordersize 0
	hyprctl setprop active no_blur 1
	hyprctl setprop active no_shadow 1
	hyprctl setprop active no_dim 1

	# Resize to ~25% of monitor width, maintaining 16:9 aspect ratio
	MONITOR=$(hyprctl activewindow -j | jq -r '.monitor')
	MONITOR_INFO=$(hyprctl monitors -j | jq -r ".[] | select(.id == $MONITOR)")
	MON_W=$(echo "$MONITOR_INFO" | jq -r '.width / .scale | floor')
	MON_H=$(echo "$MONITOR_INFO" | jq -r '.height / .scale | floor')

	WIN_W=$((MON_W / 4))
	WIN_H=$((WIN_W * 9 / 16))
	MARGIN=20
	POS_X=$((MON_W - WIN_W - MARGIN))
	POS_Y=$((MON_H - WIN_H - MARGIN))

	hyprctl dispatch resizewindowpixel exact "${WIN_W}" "${WIN_H}",activewindow
	hyprctl dispatch movewindowpixel exact "${POS_X}" "${POS_Y}",activewindow
fi
