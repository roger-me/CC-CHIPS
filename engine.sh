#!/bin/bash

# CC CHIPS — Rendering engine for Claude Code status lines
# Set CC_CHIPS_THEME to pick a theme (claude, cool, retro, cyber).
# Defaults to claude.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
THEME="${CC_CHIPS_THEME:-claude}"

# Load theme colors
THEME_FILE="${SCRIPT_DIR}/themes/${THEME}.sh"
if [ ! -f "$THEME_FILE" ]; then
    echo "CC CHIPS: theme '${THEME}' not found at ${THEME_FILE}" >&2
    exit 1
fi
source "$THEME_FILE"

input=$(cat)

# ═══════════════════════════════════════════════════════════════════
# POWERLINE CAPS (rounded pill edges)
# ═══════════════════════════════════════════════════════════════════
CAP_LEFT=$(printf '\xee\x82\xb6')           # U+E0B6 left half circle
CAP_RIGHT=$(printf '\xee\x82\xb4')          # U+E0B4 right half circle

# ═══════════════════════════════════════════════════════════════════
# NERD FONT ICONS
# ═══════════════════════════════════════════════════════════════════
ICON_FOLDER=$(printf '\xef\x81\xbc')        # U+F07C  folder-open
ICON_GITHUB=$(printf '\xef\x82\x9b')        # U+F09B  github
ICON_BRANCH=$(printf '\xee\x9c\xa5')        # U+E725  dev-git_branch
ICON_BRAIN=$(printf '\xf3\xb0\xaf\x89')     # U+F0BC9 nf-md-space_invaders
ICON_MONITOR=$(printf '\xef\x8b\x90')       # U+F2D0  fa-window_maximize
ICON_CLOCK=$(printf '\xef\x80\x97')          # U+F017  fa-clock

BOLD="\033[1m"
RESET="\033[0m"

# ═══════════════════════════════════════════════════════════════════
# EXTRACT DATA
# ═══════════════════════════════════════════════════════════════════
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // .workspace.current_dir // "."')
short_path=$(echo "$project_dir" | sed "s|$HOME|~|")

# ═══════════════════════════════════════════════════════════════════
# GIT
# ═══════════════════════════════════════════════════════════════════
git_branch=""
git_dirty=""
if [ -d "$project_dir/.git" ] || git -C "$project_dir" rev-parse --git-dir > /dev/null 2>&1; then
    git_branch=$(git -C "$project_dir" branch --show-current 2>/dev/null)
    if [ -n "$git_branch" ]; then
        if ! git -C "$project_dir" diff --quiet 2>/dev/null || ! git -C "$project_dir" diff --cached --quiet 2>/dev/null; then
            git_dirty=" ≠"
        fi
    fi
fi

# ═══════════════════════════════════════════════════════════════════
# MODEL
# ═══════════════════════════════════════════════════════════════════
# .model may be an object {id, display_name} or a plain string
model_display=$(echo "$input" | jq -r '
    if (.model | type) == "object" then
        .model.display_name // .model.id // "unknown"
    else
        .model // "unknown"
    end
')

# If we got a raw model ID (e.g. claude-sonnet-4-6), make it human-readable
if [[ "$model_display" == claude-* ]]; then
    _m="${model_display#claude-}"
    _m="${_m%-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]}"
    if [[ "$_m" =~ ^([a-z]+)-([0-9]+)-([0-9]+) ]]; then
        _family="${BASH_REMATCH[1]}"
        _family="$(printf '%s' "${_family:0:1}" | tr '[:lower:]' '[:upper:]')${_family:1}"
        model_display="${_family} ${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
    elif [[ "$_m" =~ ^([a-z]+)-([0-9]+) ]]; then
        _family="${BASH_REMATCH[1]}"
        _family="$(printf '%s' "${_family:0:1}" | tr '[:lower:]' '[:upper:]')${_family:1}"
        model_display="${_family} ${BASH_REMATCH[2]}"
    fi
fi

# ═══════════════════════════════════════════════════════════════════
# CONTEXT WINDOW
# ═══════════════════════════════════════════════════════════════════
usage=$(echo "$input" | jq '.context_window.current_usage')
input_tokens=0
output_tokens=0
cache_read=0
cache_write=0
context_pct=0

if [ "$usage" != "null" ]; then
    input_tokens=$(echo "$usage" | jq '.input_tokens // 0')
    output_tokens=$(echo "$usage" | jq '.output_tokens // 0')
    cache_read=$(echo "$usage" | jq '.cache_read_input_tokens // 0')
    cache_write=$(echo "$usage" | jq '.cache_creation_input_tokens // 0')
    current=$((input_tokens + cache_write + cache_read))
    size=$(echo "$input" | jq '.context_window.context_window_size')
    if [ "$size" != "null" ] && [ "$size" -gt 0 ] 2>/dev/null; then
        context_pct=$((current * 100 / size))
    fi
fi

# Context bar (5 blocks)
filled=$((context_pct * 5 / 100))
bar=""
for ((i=0; i<5; i++)); do
    if [ $i -lt $filled ]; then bar="${bar}■"; else bar="${bar}□"; fi
done

# ═══════════════════════════════════════════════════════════════════
# BUILD STATUS LINE
# ═══════════════════════════════════════════════════════════════════

# CHIP 1: folder + path
printf "${FG_LEFT}${CAP_LEFT}${RESET}"
printf "${BG_LEFT}${BOLD}${FG_LEFT_TEXT} ${ICON_FOLDER} %s ${RESET}" "$short_path"
printf "${FG_LEFT}${CAP_RIGHT}${RESET}"

# CHIP 2: git info
if [ -n "$git_branch" ]; then
    printf " "
    printf "${FG_MID}${CAP_LEFT}${RESET}"
    printf "${BG_MID}${BOLD}${FG_MID_TEXT} ${ICON_GITHUB} ${ICON_BRANCH} %s${FG_MID_TEXT}%s${FG_MID_TEXT} ${RESET}" "$git_branch" "$git_dirty"
    printf "${FG_MID}${CAP_RIGHT}${RESET}"
fi

printf " "

# CHIP 3: model + context + cost
printf "${FG_RIGHT}${CAP_LEFT}${RESET}"
current_time=$(date +"%H:%M")
printf "${BG_RIGHT}${BOLD}${FG_RIGHT_TEXT} ${ICON_BRAIN} %s ${ICON_MONITOR} %s %d%% ${ICON_CLOCK} %s ${RESET}" "$model_display" "$bar" "$context_pct" "$current_time"
printf "${FG_RIGHT}${CAP_RIGHT}${RESET}"

printf "\n"
