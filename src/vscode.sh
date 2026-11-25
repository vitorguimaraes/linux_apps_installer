#!/bin/bash
set -e

printf "\nInstalling VS Code...\n"

# Official Microsoft apt repository, so `apt upgrade` keeps VS Code updated
sudo apt-get install -y wget gpg apt-transport-https

# Download and convert the key in a temporary directory first, so a failed download
# never overwrites a keyring that is already installed
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

wget -qO "$tmp_dir/microsoft.asc" https://packages.microsoft.com/keys/microsoft.asc
gpg --dearmor -o "$tmp_dir/microsoft.gpg" "$tmp_dir/microsoft.asc"
sudo install -m 644 "$tmp_dir/microsoft.gpg" /usr/share/keyrings/microsoft.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

sudo apt-get update
sudo apt-get install -y code

printf "\nVS Code installed: %s\n" "$(dpkg-query -W -f='${Version}' code)"
