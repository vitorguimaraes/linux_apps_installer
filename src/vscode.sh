#!/bin/bash
set -e

printf "\nInstalling VS Code...\n"

# Official Microsoft apt repository, so `apt upgrade` keeps VS Code updated
sudo apt-get install -y wget gpg apt-transport-https

wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft.gpg > /dev/null

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

sudo apt-get update
sudo apt-get install -y code

printf "\nVS Code installed: %s\n" "$(code --version | head -n 1)"
