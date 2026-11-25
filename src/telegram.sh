#!/bin/bash
set -e

printf "\nInstalling Telegram...\n"

APP_ID="org.telegram.desktop"

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
    printf "No GNOME session found, Telegram was not pinned to the dock.\n"
fi

printf "\nTelegram installed!\n"
printf "*******************************************************************\n"
