#!/bin/bash
set -euo pipefail

printf "\nInstalling Dev Icons...\n"

# Works from any directory
cd "$(dirname "${BASH_SOURCE[0]}")/.."

DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
# Every Yaru variant (Yaru-magenta-dark, ...) inherits its file type icons from plain Yaru
SYSTEM_THEME="/usr/share/icons/Yaru"
USER_THEME="$DATA_HOME/icons/Yaru"

# A glob with no match expands to nothing instead of the literal pattern
# (otherwise mkdir would create a folder literally named "*")
shopt -s nullglob

if [[ ! -d "$SYSTEM_THEME" ]]; then
    printf "Yaru icon theme not found, nothing to override. Dev Icons not installed!\n"
    exit 1
fi

mimetype_dirs=("$SYSTEM_THEME"/*/mimetypes)
if [[ ${#mimetype_dirs[@]} -eq 0 ]]; then
    printf "No mimetypes folders found in %s, nothing to override. Dev Icons not installed!\n" "$SYSTEM_THEME"
    exit 1
fi

icons=(DevIcons/*.svg DevIcons/*.png)
if [[ ${#icons[@]} -eq 0 ]]; then
    printf "No icons found in DevIcons/. Dev Icons not installed!\n"
    exit 1
fi

# Checked before copying anything, so a missing tool never leaves a half installation
if ! command -v update-mime-database >/dev/null 2>&1; then
    printf "update-mime-database not found (package shared-mime-info). Dev Icons not installed!\n"
    exit 1
fi

# --- File types (Dockerfile) ---
mkdir -p "$DATA_HOME/mime/packages"
cp -v DevIcons/dockerfile.xml "$DATA_HOME/mime/packages/dev-icons.xml"
update-mime-database "$DATA_HOME/mime"

# --- Icons ---
# Icon lookup only searches the folders listed in the theme's index.theme (<size>/mimetypes).
# Files placed in the same folders of a user copy of the theme take priority over the system
# ones, so mirror each Yaru mimetypes folder (all sizes) into ~/.local/share/icons/Yaru.
count=0
for system_dir in "${mimetype_dirs[@]}"; do
    relative="${system_dir#"$SYSTEM_THEME"/}"
    mkdir -p "$USER_THEME/$relative"
    for icon in "${icons[@]}"; do
        cp "$icon" "$USER_THEME/$relative/"
        count=$((count + 1))
    done
done

printf "Dev Icons installed! (%d files copied to %s)\n" "$count" "$USER_THEME"
printf "Restart the file manager to see them: nautilus -q\n"
printf "\n*******************************************************************\n"
