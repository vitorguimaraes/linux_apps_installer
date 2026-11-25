#!/bin/bash
set -e

printf "\nInstalling DBeaver...\n"

# Official DBeaver apt repository, so `apt upgrade` always brings the latest release
# (the Flathub build lags behind upstream)
sudo apt-get install -y wget gpg

wget -qO- https://dbeaver.io/debs/dbeaver.gpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/dbeaver.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/dbeaver.gpg] https://dbeaver.io/debs/dbeaver-ce /" | sudo tee /etc/apt/sources.list.d/dbeaver.list > /dev/null

sudo apt-get update
sudo apt-get install -y dbeaver-ce

# Pin to the dock (once)
desktop_file="dbeaver-ce.desktop"
favorites=$(gsettings get org.gnome.shell favorite-apps)
if [[ "$favorites" != *"$desktop_file"* && -f "/usr/share/applications/$desktop_file" ]]; then
    gsettings set org.gnome.shell favorite-apps "${favorites%]}, '$desktop_file']"
fi

printf "\nDBeaver installed: %s\n" "$(dpkg-query -W -f='${Version}' dbeaver-ce)"
