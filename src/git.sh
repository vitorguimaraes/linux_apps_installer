#!/bin/bash
set -e

printf "\nInstalling Git...\n"

# add-apt-repository comes from this package (missing on minimal installs)
sudo apt install software-properties-common -y

sudo add-apt-repository --yes ppa:git-core/ppa
sudo apt update -y
sudo apt install git -y

# create aliases (only the ones you haven't defined yourself)
set_alias() {
    if [[ -z "$(git config --global --get "alias.$1")" ]]; then
        git config --global "alias.$1" "$2"
    fi
}

set_alias br branch
set_alias sw switch
set_alias st status
set_alias cm commit
set_alias ps push
set_alias pu pull

if command -v git >/dev/null 2>&1 && git --version >/dev/null 2>&1; then
    git --version
    printf "Git installed!"
else
    printf "Git not installed!"
    exit 1
fi
printf "\n*******************************************************************\n"
