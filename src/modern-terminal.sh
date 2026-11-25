#!/bin/bash

printf "\nInstalling Modern Terminal (Ghostty + zsh + Starship)...\n"

# Installs Ghostty, zsh (+ autosuggestions/syntax-highlighting), Starship, eza, fzf,
# FiraCode Nerd Font, the Dracula theme and the Ctrl+Alt+T shortcut
if ! bash modern-terminal/setup-ghostty.sh; then
    printf "\nModern Terminal setup failed! Check the errors above.\n"
    exit 1
fi

ghostty_check=$(command -v ghostty)
zsh_check=$(command -v zsh)
starship_check=$(command -v starship)
eza_check=$(command -v eza)
fzf_check=$(command -v fzf)
firacode_check=$(fc-list | grep -i "FiraCode Nerd")
zsh_plugins_check=$(ls /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null)

check() {
    if [[ -n "$2" ]]; then
        printf "%s installed!\n" "$1"
    else
        printf "%s not installed!\n" "$1"
    fi
}

check "Ghostty" "$ghostty_check"
check "Shell ZSH" "$zsh_check"
check "Starship" "$starship_check"
check "Eza" "$eza_check"
check "fzf" "$fzf_check"
check "FiraCode Nerd Font" "$firacode_check"
check "ZSH plugins" "$zsh_plugins_check"

if [[ -n "$ghostty_check" && -n "$zsh_check" && -n "$starship_check" &&
      -n "$eza_check" && -n "$fzf_check" && -n "$firacode_check" && -n "$zsh_plugins_check" ]]; then
    printf "Modern Terminal installed!\n"

    # Opens the customization guide + lab in the default browser
    guide="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/docs/terminal-customization.html"
    if [[ -f "$guide" ]] && command -v xdg-open >/dev/null 2>&1 && [[ -n "$DISPLAY$WAYLAND_DISPLAY" ]]; then
        printf "Opening the terminal customization guide...\n"
        nohup xdg-open "$guide" >/dev/null 2>&1 &
    fi
else
    printf "Modern Terminal not installed yet! "
    printf "Logoff and login to apply changes or check logs for errors"
fi
printf "\n******************************************************************\n"
