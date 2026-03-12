#!/usr/bin/env bash
# Sets up the default workspace layout.
# Already-running apps get moved immediately.
# Missing apps are launched in parallel, then moved via socket2 event monitoring.
# Temporary no_focus rules prevent apps from stealing focus during setup.

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

# App definitions: class -> workspace, desktop_entry
declare -A CLASS_TO_WS=([app.zen_browser.zen]=1 [foot]=2 [com.slack.Slack]=3 [com.mastermindzh.tidal-hifi]=4)
declare -A CLASS_TO_DESKTOP=(
	[app.zen_browser.zen]="app.zen_browser.zen.desktop"
	[foot]="foot.desktop"
	[com.slack.Slack]="com.slack.Slack.desktop"
	[com.mastermindzh.tidal-hifi]="com.mastermindzh.tidal-hifi.desktop"
)

# Track which classes still need a window to appear
declare -A PENDING=()

for class in "${!CLASS_TO_WS[@]}"; do
	ws="${CLASS_TO_WS[$class]}"
	address=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$class\") | .address" | head -1)

	if [[ -n "$address" ]]; then
		# Already running — move immediately
		hyprctl dispatch movetoworkspacesilent "$ws,address:$address"
	else
		# Mark as pending
		PENDING[$class]="$ws"
	fi
done

# If anything needs launching, set up temporary no_focus rules, launch, and listen
if [[ ${#PENDING[@]} -gt 0 ]]; then
	# Suppress focus stealing during setup
	for class in "${!PENDING[@]}"; do
		hyprctl keyword "windowrule[ws-setup-$class] = match:class ^(${class//./\\.})$, no_focus on"
	done

	# Launch all pending apps
	for class in "${!PENDING[@]}"; do
		app2unit -s a -- "${CLASS_TO_DESKTOP[$class]}" &
	done

	# Listen for openwindow events and move windows
	socat -U - UNIX-CONNECT:"$SOCKET" | while read -r line; do
		if [[ "$line" == openwindow\>\>* ]]; then
			data="${line#openwindow>>}"
			IFS=',' read -r addr _ws class _title <<<"$data"

			if [[ -n "${PENDING[$class]}" ]]; then
				hyprctl dispatch movetoworkspacesilent "${PENDING[$class]},address:0x$addr"
				unset 'PENDING[$class]'
				if [[ ${#PENDING[@]} -le 0 ]]; then
					hyprctl dispatch workspace 1
					break
				fi
			fi
		fi
	done &
	LISTENER_PID=$!

	# Timeout: kill listener after 30s if not all windows appeared
	(sleep 30 && kill "$LISTENER_PID" 2>/dev/null) &
	TIMEOUT_PID=$!

	wait "$LISTENER_PID" 2>/dev/null
	kill "$TIMEOUT_PID" 2>/dev/null

	# Clean up temporary no_focus rules
	for class in "${!CLASS_TO_WS[@]}"; do
		hyprctl keyword "windowrule[ws-setup-$class]:enable false" 2>/dev/null
	done
fi

# Ensure we're on workspace 1 (covers the case where all apps were already running)
hyprctl dispatch workspace 1
