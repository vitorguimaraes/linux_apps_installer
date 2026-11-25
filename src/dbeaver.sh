#!/bin/bash
set -e

printf "\nInstalling DBeaver...\n"

# Official DBeaver apt repository, so `apt upgrade` always brings the latest release
# (the Flathub build lags behind upstream)
sudo apt-get install -y wget gpg

# Download and convert the key in a temporary directory first, so a failed download
# never overwrites a keyring that is already installed
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

wget -qO "$tmp_dir/dbeaver.gpg.key" https://dbeaver.io/debs/dbeaver.gpg.key
gpg --dearmor -o "$tmp_dir/dbeaver.gpg" "$tmp_dir/dbeaver.gpg.key"
sudo install -m 644 "$tmp_dir/dbeaver.gpg" /usr/share/keyrings/dbeaver.gpg

echo "deb [signed-by=/usr/share/keyrings/dbeaver.gpg] https://dbeaver.io/debs/dbeaver-ce /" | sudo tee /etc/apt/sources.list.d/dbeaver.list > /dev/null

sudo apt-get update
sudo apt-get install -y dbeaver-ce

# Pin to the dock (once). Skipped when there is no GNOME session to talk to
desktop_file="dbeaver-ce.desktop"
if favorites=$(gsettings get org.gnome.shell favorite-apps 2>/dev/null); then
    if [[ "$favorites" != *"$desktop_file"* && -f "/usr/share/applications/$desktop_file" ]]; then
        if [[ "$favorites" == "[]" || "$favorites" == "@as []" ]]; then
            gsettings set org.gnome.shell favorite-apps "['$desktop_file']"
        else
            gsettings set org.gnome.shell favorite-apps "${favorites%]}, '$desktop_file']"
        fi
    fi
else
    printf "No GNOME session found, DBeaver was not pinned to the dock.\n"
fi

printf "\nDBeaver installed: %s\n" "$(dpkg-query -W -f='${Version}' dbeaver-ce)"
