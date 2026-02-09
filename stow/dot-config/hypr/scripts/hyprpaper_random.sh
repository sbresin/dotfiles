#!/usr/bin/env bash

# Set wallpaper directory (default to ~/wallpapers/)
: "${WALLPAPER_DIR:=$HOME/wallpapers/}"

CURRENT_WALL=$(readlink -f "$HOME/current_wallpaper.jpg" 2>/dev/null)

# Try to find a wallpaper different from the current one
if [[ -n "$CURRENT_WALL" ]]; then
	WALLPAPER=$(find "$WALLPAPER_DIR" -type f -name "*.jpg" ! -path "$CURRENT_WALL" | shuf -n 1)
fi

# Fall back to any wallpaper if none found (e.g., only one wallpaper exists)
if [[ -z "$WALLPAPER" ]]; then
	WALLPAPER=$(find "$WALLPAPER_DIR" -type f -name "*.jpg" | shuf -n 1)
fi

if [[ -z "$WALLPAPER" ]]; then
	echo "Error: No wallpapers found in $WALLPAPER_DIR" >&2
	exit 1
fi

rm -f "$HOME/current_wallpaper.jpg" 2>/dev/null

SYMLINK_PATH="$HOME/current_wallpaper.jpg"
ln -sf "$WALLPAPER" "$SYMLINK_PATH"

if [[ ! -L "$SYMLINK_PATH" ]]; then
	echo "Error: Failed to create symlink at $SYMLINK_PATH" >&2
	exit 1
fi

hyprctl hyprpaper wallpaper ",$SYMLINK_PATH"
