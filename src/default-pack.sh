#!/bin/bash

# Base setup that always runs after the menu: GNOME tweaks, everyday apps and
# keyboard shortcuts. Safe to run more than once. Run it from the project root.

printf "\nApplying the default pack...\n"

# --- Git ---
# The PPA build is installed by src/git.sh (the Git menu option also upgrades it)
if ! command -v git >/dev/null 2>&1; then
    bash src/git.sh
fi

# --- Apt apps and tools ---
# flameshot: screenshots | simplescreenrecorder: screen recording | fd-find/bat/ripgrep/micro/bashtop: CLI tools
# dconf-editor: browse GNOME settings | gnome-shell-extension-manager: install GNOME extensions
sudo apt install -y \
    flameshot simplescreenrecorder \
    fd-find bat ripgrep micro bashtop \
    dconf-editor gnome-shell-extension-manager
# To get Dash to Panel: open Extension Manager > Browse > 'Dash to Panel'

# --- Google Chrome (.deb, from Google) ---
if ! command -v google-chrome >/dev/null 2>&1; then
    bash src/chrome.sh
fi

# --- Flatpak apps ---
flatpak_install() {
    flatpak info "$1" >/dev/null 2>&1 || flatpak install flathub "$1" -y
}
flatpak_install org.qbittorrent.qBittorrent
flatpak_install org.videolan.VLC

# --- tldr (npm package, needs Node via nvm) ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
if ! command -v tldr >/dev/null 2>&1; then
    if ! command -v npm >/dev/null 2>&1; then
        bash src/node.sh
        # node.sh runs in its own process, so load nvm again to get npm in this one
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    fi
    npm install -g tldr
fi

# --- Poppins font ---
mkdir -p "$HOME/.local/share/fonts"
cp -u Poppins/*.ttf "$HOME/.local/share/fonts/"
fc-cache -f "$HOME/.local/share/fonts"

# --- GNOME settings ---
# Night light: 2700K from 22:00 until 21:58 (practically always on)
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 22
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 21.98
gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 2700

gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Hide the snap folder in the file manager (once)
grep -qxF snap "$HOME/.hidden" 2>/dev/null || echo snap >> "$HOME/.hidden"

# --- Keyboard shortcuts ---
# Turn off GNOME defaults that clash with Flameshot and the VS Code shortcuts
gsettings set org.gnome.shell.keybindings screenshot "[]"
gsettings set org.gnome.shell.keybindings screenshot-window "[]"
gsettings set org.gnome.shell.keybindings show-screenshot-ui "[]"
gsettings set org.gnome.shell.keybindings show-screen-recording-ui "[]"
gsettings set org.gnome.shell.keybindings toggle-message-tray "[]"
gsettings set org.gnome.shell.keybindings toggle-application-view "[]"
# Moving a window between workspaces clashes with VS Code's copy line up/down
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-down "[]"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-up "[]"

gsettings set org.gnome.settings-daemon.plugins.media-keys calculator "['<Super>c']"
gsettings set org.gnome.settings-daemon.plugins.media-keys www "['<Super>f']"

MEDIA_KEYS=org.gnome.settings-daemon.plugins.media-keys
BINDINGS_PATH=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings

# add_shortcut <id> <name> <command> <binding>
# Adds a custom shortcut to the existing list, so shortcuts created elsewhere
# (like Ctrl+Alt+T for Ghostty) are kept.
add_shortcut() {
    local key="$BINDINGS_PATH/$1/" current new
    current=$(gsettings get $MEDIA_KEYS custom-keybindings)
    if [[ "$current" != *"$key"* ]]; then
        if [[ "$current" == "@as []" || "$current" == "[]" ]]; then
            new="['$key']"
        else
            new="${current%]}, '$key']"
        fi
        gsettings set $MEDIA_KEYS custom-keybindings "$new"
    fi
    gsettings set "$MEDIA_KEYS.custom-keybinding:$key" name "$2"
    gsettings set "$MEDIA_KEYS.custom-keybinding:$key" command "$3"
    gsettings set "$MEDIA_KEYS.custom-keybinding:$key" binding "$4"
}

add_shortcut flameshot 'Flameshot' 'flameshot gui' 'Print'
add_shortcut vscode    'VSCode'    'code' '<Super>V'
add_shortcut dbeaver   'DBeaver'   'dbeaver' '<Super>B'
add_shortcut insomnia  'Insomnia'  'flatpak run rest.insomnia.Insomnia' '<Super>I'
add_shortcut obsidian  'Obsidian'  'flatpak run md.obsidian.Obsidian' '<Super>O'
add_shortcut discord   'Discord'   'flatpak run com.discordapp.Discord' '<Super>D'

printf "\nDefault pack applied!\n"
printf "*******************************************************************\n"
