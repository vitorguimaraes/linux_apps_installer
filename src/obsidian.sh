#!/bin/bash
set -e

printf "\nInstalling Obsidian...\n"

# Works from any directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

APP_ID="md.obsidian.Obsidian"
VAULT_DIR="$HOME/.ObsidianVault"
VAULT_URL="https://github.com/vitorguimaraes/ObsidianVault.git"

flatpak info "$APP_ID" >/dev/null 2>&1 || flatpak install flathub "$APP_ID" -y

# Pin to the dock (once). Skipped when there is no GNOME session to talk to
desktop_file="$APP_ID.desktop"
if favorites=$(gsettings get org.gnome.shell favorite-apps 2>/dev/null); then
    if [[ "$favorites" != *"$desktop_file"* ]]; then
        if [[ "$favorites" == "[]" || "$favorites" == "@as []" ]]; then
            gsettings set org.gnome.shell favorite-apps "['$desktop_file']"
        else
            gsettings set org.gnome.shell favorite-apps "${favorites%]}, '$desktop_file']"
        fi
    fi
else
    printf "No GNOME session found, Obsidian was not pinned to the dock.\n"
fi

# --- Vault ---
if ! command -v git >/dev/null 2>&1; then
    bash "$SCRIPT_DIR/git.sh"
fi

if [[ -d "$VAULT_DIR/.git" ]]; then
    # Never touch an existing vault: it may hold notes that are not committed yet
    printf "Vault already cloned at %s, leaving it as is.\n" "$VAULT_DIR"
elif [[ -e "$VAULT_DIR" ]]; then
    printf "%s exists but is not a git clone. Move it away and run again. Vault not cloned!\n" "$VAULT_DIR"
    exit 1
else
    git clone "$VAULT_URL" "$VAULT_DIR"
fi

printf "\nObsidian installed!\n"
printf "*******************************************************************\n"
