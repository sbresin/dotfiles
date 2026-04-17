#!/usr/bin/env bash
# Sesh preview script for fzf
# Shows session windows + active pane capture for tmux sessions,
# or directory tree for zoxide/find entries.
#
# Usage: preview.sh <fzf-line>
#   where <fzf-line> is the raw sesh list --icons output (with ANSI + icon)

set -euo pipefail

# ── Rose Pine colours (true-colour ANSI) ────────────────────────────
RST='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
# Rose Pine palette
TEXT='\033[38;2;224;222;244m'   # #e0def4
SUBTLE='\033[38;2;110;106;134m' # #6e6a86
GOLD='\033[38;2;246;193;119m'   # #f6c177
ROSE='\033[38;2;235;188;186m'   # #ebbcba
LOVE='\033[38;2;235;111;146m'   # #eb6f92
FOAM='\033[38;2;156;207;216m'   # #9ccfd8
IRIS='\033[38;2;196;167;231m'   # #c4a7e7
PINE='\033[38;2;49;116;143m'    # #31748f

# ── Helpers ──────────────────────────────────────────────────────────
strip_ansi() {
  sed 's/\x1b\[[0-9;]*m//g'
}

hr() {
  local width=${1:-45}
  printf "${SUBTLE}"
  printf '%.0s━' $(seq 1 "$width")
  printf "${RST}\n"
}

# ── Parse input ──────────────────────────────────────────────────────
raw="$*"
# Strip ANSI codes and leading/trailing whitespace
clean=$(echo "$raw" | strip_ansi | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# The format is: "<icon> <name>" — strip the first non-space token (nerd font icon)
# Icons are multi-byte UTF-8 chars; after stripping ANSI, format is "<icon> <name>"
name=$(echo "$clean" | sed 's/^[^ ]* //')

# If name is empty (e.g., plain path from fd), use the whole cleaned string
[[ -z "$name" ]] && name="$clean"

# Expand ~ to $HOME for path detection
expanded="${name/#\~/$HOME}"

# ── Detect type: tmux session vs directory ───────────────────────────
is_tmux_session=false
if tmux has-session -t "=$name" 2>/dev/null; then
  is_tmux_session=true
fi

# ── TMUX SESSION PREVIEW ────────────────────────────────────────────
if $is_tmux_session; then
  # Get session working directory (list-sessions is reliable from any context)
  session_path=$(tmux list-sessions -F '#{session_name}	#{session_path}' 2>/dev/null \
    | awk -F'\t' -v s="$name" '$1 == s { print $2; exit }')

  # Header: session name
  printf "${BOLD}${FOAM} %s${RST}" "$name"

  # Show path if available
  if [[ -n "$session_path" ]]; then
    display_path=$(echo "$session_path" | sed "s|^$HOME|~|")
    printf "  ${SUBTLE}%s${RST}" "$display_path"
  fi
  printf "\n"

  # Git branch
  if [[ -n "$session_path" ]] && git -C "$session_path" rev-parse --is-inside-work-tree &>/dev/null; then
    branch=$(git -C "$session_path" symbolic-ref --short HEAD 2>/dev/null || git -C "$session_path" rev-parse --short HEAD 2>/dev/null || echo "")
    if [[ -n "$branch" ]]; then
      # Check for uncommitted changes
      dirty=""
      if ! git -C "$session_path" diff --quiet HEAD 2>/dev/null; then
        dirty=" ${LOVE}*${RST}"
      fi
      printf "${IRIS}  %s${RST}%b\n" "$branch" "$dirty"
    fi
  fi

  printf "\n"

  # ── Window list ──────────────────────────────────────────────────
  printf "${BOLD}${GOLD} Windows${RST}\n"
  hr 45

  # Collect windows: index, name, command, active flag
  active_window=""
  while IFS=$'\t' read -r win_idx win_name win_cmd win_active win_panes; do
    if [[ "$win_active" == "1" ]]; then
      marker="${FOAM}${BOLD} ← ${RST}"
      active_window="$win_idx"
    else
      marker=""
    fi

    # Pad columns for alignment
    printf "  ${TEXT}%-3s ${ROSE}%-14s ${SUBTLE}%-12s${RST}%b\n" \
      "$win_idx" "$win_name" "$win_cmd" "$marker"
  done < <(tmux list-windows -t "=$name" -F "#{window_index}	#{window_name}	#{pane_current_command}	#{window_active}	#{window_panes}")

  printf "\n"

  # ── Pane capture of the active window ────────────────────────────
  if [[ -n "${active_window:-}" ]]; then
    # Get the active pane in the active window
    active_pane=$(tmux display-message -t "=$name:${active_window}" -p '#{pane_id}' 2>/dev/null || echo "")

    if [[ -n "$active_pane" ]]; then
      printf "${BOLD}${GOLD} Active Pane${RST}  ${SUBTLE}(window %s)${RST}\n" "$active_window"
      hr 45

      # Calculate available lines for pane preview, aligned to bottom
      # FZF_PREVIEW_LINES is set by fzf in the preview subprocess
      fzf_lines="${FZF_PREVIEW_LINES:-40}"

      # Header lines already printed: session + branch + blank + Windows hdr + hr + windows + blank + Pane hdr + hr
      win_count=$(tmux list-windows -t "=$name" -F x 2>/dev/null | wc -l)
      header_lines=$((win_count + 9))
      available=$((fzf_lines - header_lines))
      (( available < 5 )) && available=5

      # Get pane height so we can grab the bottom portion (most relevant)
      pane_height=$(tmux display-message -t "$active_pane" -p '#{pane_height}' 2>/dev/null || echo "80")
      start_line=$((pane_height - available))
      (( start_line < 0 )) && start_line=0

      # Capture with -e to preserve ANSI colours, aligned to bottom-left
      captured=$(tmux capture-pane -t "$active_pane" -e -p -S "$start_line" 2>/dev/null || echo "")
      if [[ -n "$captured" ]]; then
        # Trim leading blank lines
        echo "$captured" | sed '/./,$!d'
      else
        printf "${SUBTLE}  (empty pane)${RST}\n"
      fi
    fi
  fi

# ── DIRECTORY PREVIEW ────────────────────────────────────────────────
else
  # Header
  printf "${BOLD}${FOAM} %s${RST}\n" "$name"

  # Check if directory exists
  if [[ -d "$expanded" ]]; then
    # Git branch
    if git -C "$expanded" rev-parse --is-inside-work-tree &>/dev/null; then
      branch=$(git -C "$expanded" symbolic-ref --short HEAD 2>/dev/null || git -C "$expanded" rev-parse --short HEAD 2>/dev/null || echo "")
      if [[ -n "$branch" ]]; then
        dirty=""
        if ! git -C "$expanded" diff --quiet HEAD 2>/dev/null; then
          dirty=" ${LOVE}*${RST}"
        fi
        printf "${IRIS}  %s${RST}%b\n" "$branch" "$dirty"
      fi
    fi

    printf "\n"
    printf "${BOLD}${GOLD} Files${RST}\n"
    hr 45

    # Use eza if available, otherwise fallback to ls
    if command -v eza &>/dev/null; then
      eza --tree --level=2 --icons --color=always \
        --git-ignore --ignore-glob='.git|node_modules|__pycache__|.venv|target' \
        "$expanded" 2>/dev/null | head -40
    else
      ls -lA --color=always "$expanded" 2>/dev/null | head -30
    fi
  else
    printf "\n${SUBTLE}  Directory does not exist yet — sesh will create the session on connect.${RST}\n"
  fi
fi
