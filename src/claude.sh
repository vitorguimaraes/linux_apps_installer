#!/bin/bash
set -eo pipefail

printf "\nInstalling Claude Code and its statusline...\n"

# Works from any directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATUSLINE_SOURCE="$PROJECT_DIR/claude/statusline.sh"
STATUSLINE_TARGET="$HOME/.claude/statusline.sh"
# The "~" is written literally into settings.json and expanded by the shell Claude Code runs the command in,
# so the settings stay valid if the home folder moves
# shellcheck disable=SC2088
STATUSLINE_COMMAND='~/.claude/statusline.sh'
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
timestamp=$(date +%Y%m%d-%H%M%S)

# The native installer puts the claude launcher in ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

if [[ ! -f "$STATUSLINE_SOURCE" ]]; then
    printf "Missing %s. Claude Code not installed!\n" "$STATUSLINE_SOURCE"
    exit 1
fi

# --- Claude Code (official native installer, does not need Node) ---
if command -v claude >/dev/null 2>&1; then
    printf "Claude Code is already installed. It updates itself; run 'claude update' to update now.\n"
else
    if ! command -v curl >/dev/null 2>&1; then
        sudo apt install curl -y
    fi
    # Download first and run afterwards, so a dropped connection never runs half a script
    tmp_dir=$(mktemp -d)
    trap 'rm -rf "$tmp_dir"' EXIT
    curl -fsSL -o "$tmp_dir/install.sh" https://claude.ai/install.sh
    bash "$tmp_dir/install.sh"
    hash -r
fi

if ! command -v claude >/dev/null 2>&1; then
    printf "Claude Code not installed!\n"
    exit 1
fi
claude --version
printf "Claude Code installed!\n"

# The statusline script and the settings merge below both use jq
if ! command -v jq >/dev/null 2>&1; then
    sudo apt install jq -y
fi

# backup_file <file>: copies it to <file>.bak.<date-time> (same convention as the Modern Terminal setup)
backup_file() {
    cp "$1" "$1.bak.$timestamp"
    printf "  Backup: %s.bak.%s\n" "$1" "$timestamp"
}

# --- Statusline script: Powerline blocks, Dracula colors, one color per item ---
printf "\nInstalling the statusline...\n"
mkdir -p "$(dirname "$STATUSLINE_TARGET")"
if [[ -f "$STATUSLINE_TARGET" ]] && ! cmp -s "$STATUSLINE_SOURCE" "$STATUSLINE_TARGET"; then
    backup_file "$STATUSLINE_TARGET"
fi
cp "$STATUSLINE_SOURCE" "$STATUSLINE_TARGET"
chmod +x "$STATUSLINE_TARGET"
printf "  Script written to %s\n" "$STATUSLINE_TARGET"

# --- Tell Claude Code to use it (merged into the existing settings, other keys are kept) ---
if [[ -s "$CLAUDE_SETTINGS" ]]; then
    if ! jq -e 'type == "object"' "$CLAUDE_SETTINGS" >/dev/null 2>&1; then
        printf "%s is not a valid JSON object. Fix or move it and run again. Statusline not activated!\n" "$CLAUDE_SETTINGS"
        exit 1
    fi
    current=$(cat "$CLAUDE_SETTINGS")
else
    current='{}'
fi

# refreshInterval (re-render every N seconds, so the time marker keeps moving) needs Claude Code 2.1.97 or newer
claude_version=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)
supports_refresh=false
if [[ -n "$claude_version" && "$(printf '%s\n%s\n' 2.1.97 "$claude_version" | sort -V | head -1)" == "2.1.97" ]]; then
    supports_refresh=true
fi

updated=$(printf '%s' "$current" | jq --arg cmd "$STATUSLINE_COMMAND" --argjson refresh "$supports_refresh" '
    .statusLine = ({type: "command", command: $cmd, padding: 0}
        + (if $refresh then {refreshInterval: ((try .statusLine.refreshInterval catch null) // 10)} else {} end))')

if [[ "$(printf '%s' "$current" | jq -S .)" == "$(printf '%s' "$updated" | jq -S .)" ]]; then
    printf "  Claude Code settings already point to the statusline.\n"
else
    previous_command=$(printf '%s' "$current" | jq -r '(try .statusLine.command catch empty) // empty' 2>/dev/null || true)
    if [[ -s "$CLAUDE_SETTINGS" ]]; then
        backup_file "$CLAUDE_SETTINGS"
    fi
    if [[ -n "$previous_command" && "$previous_command" != "$STATUSLINE_COMMAND" ]]; then
        printf "  Replacing the previous statusLine command: %s\n" "$previous_command"
    fi
    tmp_file=$(mktemp)
    printf '%s\n' "$updated" > "$tmp_file"
    # cat into the file (not mv) keeps its permissions and ownership
    cat "$tmp_file" > "$CLAUDE_SETTINGS"
    rm -f "$tmp_file"
    printf "  statusLine set in %s\n" "$CLAUDE_SETTINGS"
fi

# --- Test render with sample data, so the result can be checked right here ---
printf "\nTest render (sample data):\n"
now=$(date +%s)
sample=$(jq -n --argjson now "$now" '{
    model: {id: "claude-sonnet-5-5", display_name: "Sonnet 5.5"},
    effort: {level: "high"},
    context_window: {context_window_size: 200000, used_percentage: 42},
    rate_limits: {
        five_hour: {used_percentage: 27, resets_at: ($now + 9000)},
        seven_day: {used_percentage: 61, resets_at: ($now + 259200)}
    }
}')
rendered=$(printf '%s' "$sample" | timeout 30 "$STATUSLINE_TARGET" 2>/dev/null || true)
if [[ -n "$rendered" ]]; then
    printf "  %s\n" "$rendered"
    printf "\nStatusline installed! Open a new Claude Code session (or restart the open ones) to see it.\n"
else
    printf "The statusline printed nothing for the sample data. Statusline not working!\n"
    printf "Try it by hand: echo '{\"model\":{\"display_name\":\"Test\"}}' | %s\n" "$STATUSLINE_TARGET"
    exit 1
fi
printf "\n*******************************************************************\n"
