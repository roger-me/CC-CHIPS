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
ICON_HOURGLASS=$(printf '\xef\x89\x93')     # U+F253  fa-hourglass-half
ICON_CALENDAR=$(printf '\xef\x81\xb3')      # U+F073  fa-calendar

BOLD="\033[1m"
RESET="\033[0m"
DIM="\033[2m"

# ═══════════════════════════════════════════════════════════════════
# OAUTH TOKEN RESOLUTION
# ═══════════════════════════════════════════════════════════════════
_parse_oauth_token() {
    local blob="$1"
    [ -z "$blob" ] && return 1
    local token
    token=$(echo "$blob" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
    if [ -n "$token" ] && [ "$token" != "null" ]; then
        echo "$token"
        return 0
    fi
    return 1
}

get_oauth_token() {
    # 1. Explicit env var override
    if [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
        echo "$CLAUDE_CODE_OAUTH_TOKEN"
        return 0
    fi
    # 2. macOS Keychain
    if command -v security >/dev/null 2>&1; then
        _parse_oauth_token "$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)" && return 0
    fi
    # 3. Linux credentials file
    if [ -f "${HOME}/.claude/.credentials.json" ]; then
        _parse_oauth_token "$(cat "${HOME}/.claude/.credentials.json" 2>/dev/null)" && return 0
    fi
    # 4. GNOME Keyring via secret-tool
    if command -v secret-tool >/dev/null 2>&1; then
        _parse_oauth_token "$(timeout 2 secret-tool lookup service "Claude Code-credentials" 2>/dev/null)" && return 0
    fi
    echo ""
}

# ═══════════════════════════════════════════════════════════════════
# USAGE API (5h / weekly / extra)
# ═══════════════════════════════════════════════════════════════════
USAGE_CACHE="/tmp/claude/statusline-usage-cache.json"
USAGE_CACHE_LOCK="/tmp/claude/statusline-usage-refresh.lock"
USAGE_CACHE_MAX_AGE=60

_refresh_usage_cache() {
    # Lock to prevent concurrent refreshes
    if [ -f "$USAGE_CACHE_LOCK" ]; then
        local lock_age lock_mtime now
        lock_mtime=$(stat -f %m "$USAGE_CACHE_LOCK" 2>/dev/null || stat -c %Y "$USAGE_CACHE_LOCK" 2>/dev/null)
        now=$(date +%s)
        lock_age=$(( now - lock_mtime ))
        # Stale lock (>15s) means a previous refresh died, remove it
        [ "$lock_age" -lt 15 ] && return
    fi
    echo $$ > "$USAGE_CACHE_LOCK"
    trap 'rm -f "$USAGE_CACHE_LOCK"' EXIT

    local token
    token=$(get_oauth_token)
    if [ -n "$token" ] && [ "$token" != "null" ]; then
        local response
        response=$(curl -s --max-time 5 \
            -H "Accept: application/json" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $token" \
            -H "anthropic-beta: oauth-2025-04-20" \
            "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)
        if [ -n "$response" ] && echo "$response" | jq -e '.five_hour' >/dev/null 2>&1; then
            echo "$response" > "$USAGE_CACHE"
        else
            # Touch cache so we don't retry every render on persistent failures
            touch "$USAGE_CACHE" 2>/dev/null
        fi
    else
        touch "$USAGE_CACHE" 2>/dev/null
    fi
    rm -f "$USAGE_CACHE_LOCK"
}

fetch_usage_data() {
    mkdir -p /tmp/claude

    if [ -f "$USAGE_CACHE" ]; then
        local cache_mtime now
        cache_mtime=$(stat -f %m "$USAGE_CACHE" 2>/dev/null || stat -c %Y "$USAGE_CACHE" 2>/dev/null)
        now=$(date +%s)
        if [ $(( now - cache_mtime )) -ge "$USAGE_CACHE_MAX_AGE" ]; then
            # Stale: kick off background refresh, serve stale data now
            _refresh_usage_cache &
            disown 2>/dev/null
        fi
        cat "$USAGE_CACHE" 2>/dev/null
        return
    fi

    # No cache at all: synchronous first fetch (unavoidable)
    local token
    token=$(get_oauth_token)
    if [ -n "$token" ] && [ "$token" != "null" ]; then
        local response
        response=$(curl -s --max-time 3 \
            -H "Accept: application/json" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $token" \
            -H "anthropic-beta: oauth-2025-04-20" \
            "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)
        if [ -n "$response" ] && echo "$response" | jq -e '.five_hour' >/dev/null 2>&1; then
            echo "$response" > "$USAGE_CACHE"
            echo "$response"
            return
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════
# DATE HELPERS
# ═══════════════════════════════════════════════════════════════════
iso_to_epoch() {
    local iso_str="$1"
    local epoch
    # Try GNU date first (Linux)
    epoch=$(date -d "${iso_str}" +%s 2>/dev/null)
    if [ -n "$epoch" ]; then echo "$epoch"; return 0; fi
    # BSD date (macOS)
    local stripped="${iso_str%%.*}"
    stripped="${stripped%%Z}"
    stripped="${stripped%%+*}"
    if [[ "$iso_str" == *"Z"* ]] || [[ "$iso_str" == *"+00:00"* ]]; then
        epoch=$(env TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
    else
        epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
    fi
    if [ -n "$epoch" ]; then echo "$epoch"; return 0; fi
    return 1
}

format_reset_time() {
    local iso_str="$1"
    [ -z "$iso_str" ] || [ "$iso_str" = "null" ] && return
    local epoch
    epoch=$(iso_to_epoch "$iso_str")
    [ -z "$epoch" ] && return
    # Format: "H:MM, DayOfWeek, DD/MM/YYYY" (force English)
    # Try BSD date (macOS) first, then GNU date (Linux)
    LC_TIME=en_US.UTF-8 date -j -r "$epoch" +"%-H:%M, %A, %d/%m/%Y" 2>/dev/null || \
    LC_TIME=en_US.UTF-8 date -d "@$epoch" +"%-H:%M, %A, %d/%m/%Y" 2>/dev/null
}

# Build a usage bar with color that shifts based on percentage.
# Usage: build_usage_bar <pct> <width>
build_usage_bar() {
    local pct=$1 width=$2
    [ "$pct" -lt 0 ] 2>/dev/null && pct=0
    [ "$pct" -gt 100 ] 2>/dev/null && pct=100
    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))
    local COLOR_GREEN="\033[38;2;0;160;0m"
    local COLOR_ORANGE="\033[38;2;255;176;85m"
    local COLOR_RED="\033[38;2;255;85;85m"
    local COLOR_EMPTY="\033[38;2;80;80;80m"
    local bar=""
    for ((i=1; i<=width; i++)); do
        if [ $i -le $filled ]; then
            if [ $i -le 4 ]; then bar+="${COLOR_GREEN}●"
            elif [ $i -le 7 ]; then bar+="${COLOR_ORANGE}●"
            else bar+="${COLOR_RED}●"
            fi
        else
            bar+="${COLOR_EMPTY}○"
        fi
    done
    printf "%b${RESET}" "$bar"
}

# ═══════════════════════════════════════════════════════════════════
# EXTRACT DATA
# ═══════════════════════════════════════════════════════════════════
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // .workspace.current_dir // "."')
short_path=$(basename "$project_dir")

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

# Context bar (5 blocks, plain text for chip embedding)
filled=$((context_pct * 5 / 100))
bar=""
for ((i=0; i<5; i++)); do
    if [ $i -lt $filled ]; then bar="${bar}●"; else bar="${bar}○"; fi
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
printf "${BG_RIGHT}${BOLD}${FG_RIGHT_TEXT} ${ICON_BRAIN} %s ${ICON_MONITOR} %s %d%% ${RESET}" "$model_display" "$bar" "$context_pct"
printf "${FG_RIGHT}${CAP_RIGHT}${RESET}"

# ═══════════════════════════════════════════════════════════════════
# ROW 2: USAGE CHIPS (5h / weekly / extra)
# ═══════════════════════════════════════════════════════════════════
api_usage=$(fetch_usage_data)

COLOR_WHITE="\033[38;2;220;220;220m"

render_usage_row() {
    local label="$1" pct="$2" reset_time="$3" width=10
    local usage_bar
    usage_bar=$(build_usage_bar "$pct" "$width")
    printf "\n${COLOR_WHITE}${BOLD}%-8s${RESET} " "$label"
    printf "%b" "$usage_bar"
    printf "${COLOR_WHITE}%3s%% used ${DIM}|${RESET} ${COLOR_WHITE}Resets: %s${RESET}" "$pct" "$reset_time"
}

if [ -n "$api_usage" ]; then
    # Extract all fields in one jq call
    usage_fields=$(echo "$api_usage" | jq -r '
        [.five_hour.utilization // 0, .five_hour.resets_at // "",
         .seven_day.utilization // 0, .seven_day.resets_at // ""]
        | map(tostring) | join("\t")
    ' 2>/dev/null)

    if [ -n "$usage_fields" ]; then
        IFS=$'\t' read -r fh_util fh_reset sd_util sd_reset <<< "$usage_fields"
        five_hour_pct=$(awk "BEGIN {printf \"%.0f\", $fh_util}")
        seven_day_pct=$(awk "BEGIN {printf \"%.0f\", $sd_util}")

        render_usage_row "Current:" "$five_hour_pct" "$(format_reset_time "$fh_reset")"
        render_usage_row "Weekly:" "$seven_day_pct" "$(format_reset_time "$sd_reset")"
    fi
fi

printf "\n"
