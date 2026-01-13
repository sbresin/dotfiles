#!/usr/bin/env bash

# Set wallpaper directory (default to ~/wallpapers/)
: "${WALLPAPER_DIR:=$HOME/wallpapers/}"

CURRENT_WALL=$(readlink -f "$HOME/current_wallpaper.jpg" 2>/dev/null)

if [[ -n "$CURRENT_WALL" ]]; then
	WALLPAPER=$(find "$WALLPAPER_DIR" -type f -name "*.jpg" ! -name "$(basename "$CURRENT_WALL")" | shuf -n 1)
else
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
