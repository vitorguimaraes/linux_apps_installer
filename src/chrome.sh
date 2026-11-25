#!/bin/bash
set -e

printf "\nInstalling Chrome...\n"

if [[ "$(dpkg --print-architecture)" != "amd64" ]]; then
    printf "Google Chrome only ships a .deb for amd64. Chrome not installed!\n"
    exit 1
fi

# Work in a temporary directory so nothing depends on (or pollutes) the current one
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

wget -q --show-progress -O "$tmp_dir/google-chrome.deb" \
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

# apt (not dpkg) so missing dependencies are installed too
sudo apt install -y "$tmp_dir/google-chrome.deb"
