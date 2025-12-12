#!/usr/bin/env bash

# Handle the initial state on startup
~/.config/hypr/scripts/monitor_toggle.sh

# Listen for monitor events using socat
# socat listens to the Hyprland socket and pipes output to the while loop
socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR"/hypr/"$HYPRLAND_INSTANCE_SIGNATURE"/.socket2.sock | while read -r line; do
	# Events look like "monitoradded>>DP-1" or "monitorremoved>>DP-1"
	if [[ "$line" == "monitoradded"* ]] || [[ "$line" == "monitorremoved"* ]]; then
		~/.config/hypr/scripts/monitor_toggle.sh
	fi
done
