#!/bin/bash
set -e

# Removes apps this setup doesn't use. APT packages only: Snap (Firefox, firmware
# updater, ...) and ~/snap are never touched, and accessibility tools and Bluetooth are kept.

printf "\nRemoving junk apps...\n"

# Plain names must exist in the repos (apt aborts the whole command on an unknown
# name); patterns may match nothing.
packages=(
    aisleriot '*brasero*'
    cdrdao '*dvd*' evolution evolution-ews evolution-common '*evolution-plugin*' emacs '*evince*' '*folks*'
    gigolo '*gimp*' gamemode '*gnome-todo*' '*gedit*' gnome-clocks gnome-user-docs
    gnome-calendar gnome-contacts gnome-font-viewer gnome-maps gnome-mines
    gnome-power-manager gnome-screenshot gnome-sound-recorder gnome-sudoku
    gnome-system-monitor gnome-tour gnome-weather
    '*libgnome-games*' '*libreoffice*' '*mahjongg*' '*mythes*' mousepad
    '*openoffice*' onboard parole pidgin pitivi ppp
    quadrapassel '*remmina*' '*rhythmbox*' shotwell sgt-puzzles
    totem totem-common totem-plugins '*transmission*' '*thunderbird*' xfburn xorg-docs-core
)

to_purge=()
for package in "${packages[@]}"; do
    if [[ "$package" == *'*'* ]] || apt-cache show "$package" >/dev/null 2>&1; then
        to_purge+=("$package")
    fi
done

# Show exactly what would be removed before doing anything
# (captured first: the exit status of a pipeline comes from its last command, not from grep)
to_remove=$(apt-get -s purge "${to_purge[@]}" | awk '/^Purg/ {print "  " $2}')
if [[ -z "$to_remove" ]]; then
    printf "\nNothing to remove, none of these apps are installed.\n"
    exit 0
fi
printf "\nThe following packages will be removed:\n%s\n" "$to_remove"

# No terminal to answer on (read fails) counts as "no"
read -rp $'\nContinue? [y/N] ' answer || answer=""
if [[ "$answer" != [yY] ]]; then
    printf "Aborted, nothing was removed.\n"
    exit 0
fi

sudo apt purge "${to_purge[@]}" -y

sudo apt clean -y
sudo apt autoremove -y
sudo apt -f install -y

printf "\nJunk apps removed!\n"
printf "*******************************************************************\n"
