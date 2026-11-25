#!/bin/bash
# No `set -u`: nvm.sh reads variables that may be unset
set -eo pipefail

printf "\nInstalling NodeJS...\n"

# Works from any directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export NVM_DIR="$HOME/.nvm"

if ! command -v git >/dev/null 2>&1; then
    bash "$SCRIPT_DIR/git.sh"
fi

# --- nvm (latest tagged release) ---
if [[ -d "$NVM_DIR/.git" ]]; then
    git -C "$NVM_DIR" fetch --tags --quiet
elif [[ -e "$NVM_DIR" ]]; then
    printf "%s exists but is not a git clone of nvm. Remove or move it and run again. Node not installed!\n" "$NVM_DIR"
    exit 1
else
    git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
fi
git -C "$NVM_DIR" checkout --quiet \
    "$(git -C "$NVM_DIR" describe --abbrev=0 --tags --match "v[0-9]*" "$(git -C "$NVM_DIR" rev-list --tags --max-count=1)")"

# --- Load nvm in new shells (added once per file) ---
# Every line has to keep the word "nvm": setup-ghostty.sh preserves the .zshrc lines that match it
add_nvm_loader() {
    local rc_file="$1"
    if [[ -f "$rc_file" ]] && grep -q 'NVM_DIR' "$rc_file"; then
        return
    fi
    cat >> "$rc_file" <<'EOF'

# nvm variables
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
EOF
}

add_nvm_loader "$HOME/.bashrc"
add_nvm_loader "$HOME/.zshrc"

# --- Node (latest) ---
# Load nvm in this process only; the rc files are for the user's next shells
. "$NVM_DIR/nvm.sh"
nvm install node

if [[ "$(command -v node)" == "$NVM_DIR/versions/node/"* ]]; then
    node -v
    printf "Node installed!"
else
    printf "Node not installed!"
    exit 1
fi
printf "\n*******************************************************************\n"
