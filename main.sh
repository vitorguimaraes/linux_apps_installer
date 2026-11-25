#!/bin/bash

# Works from any directory
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# Install Flatpak if not installed, and make sure the Flathub remote exists
# (both steps are safe to repeat)
if ! command -v flatpak >/dev/null 2>&1; then
    printf "\nInstalling Flatpak...\n\n"
    sudo apt install flatpak -y
fi
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# The menu needs zenity. It comes with Ubuntu desktop, but not with every minimal install,
# and without it the selection would silently come back empty
if ! command -v zenity >/dev/null 2>&1; then
    printf "\nInstalling zenity...\n\n"
    sudo apt install zenity -y || { printf "Could not install zenity, which the menu needs. Nothing was done.\n"; exit 1; }
fi

installed="Already installed"
not_installed="Not installed"

# Install status of each app, filled by checks() and shown in the menu
declare -A array

function checks() {

    docker_check=$(dpkg -s docker-ce 2>/dev/null | grep "Status: install ok installed")
    dockercompose_check=$(dpkg -s docker-compose-plugin 2>/dev/null | grep "Status: install ok installed")
    git_check=$(whereis git)
    node_check=$(whereis node)
    # Claude Code (native installer puts it in ~/.local/bin) with the statusline script active in its settings
    claude_check=$(command -v claude || { [[ -x "$HOME/.local/bin/claude" ]] && echo "$HOME/.local/bin/claude"; })
    claude_statusline_check=$(grep -s '"command"[[:space:]]*:[[:space:]]*"~/.claude/statusline.sh"' "$HOME/.claude/settings.json")
    zsh_check=$(whereis zsh)
    ghostty_check=$(command -v ghostty)
    starship_check=$(command -v starship)
    firacode_check=$(fc-list | grep -i "FiraCode Nerd")
    eza_check=$(command -v eza)
    fzf_check=$(command -v fzf)
    dracula_theme_check=$(gsettings get org.gnome.desktop.interface gtk-theme)
    flatpak_apps_check=$(flatpak list)
    vscode_check=$(dpkg -s code 2>/dev/null | grep "Status: install ok installed")
    dbeaver_check=$(dpkg -s dbeaver-ce 2>/dev/null | grep "Status: install ok installed")

    if [[ -n "$docker_check" && -n "$dockercompose_check" ]]; then
        array[docker]=$installed
    else
        array[docker]=$not_installed
    fi

    if [[ "$git_check" == *"/usr/bin/git"*  ]]; then
        array[git]=$installed
    else
        array[git]=$not_installed
    fi

    if [[ "$node_check" == *"versions/node/"* ]]; then
        array[node]=$installed
    else
        array[node]=$not_installed
    fi

    if [[ -n "$claude_check" && -n "$claude_statusline_check" && -x "$HOME/.claude/statusline.sh" ]]; then
        array[claude]=$installed
    else
        array[claude]=$not_installed
    fi

    if [[ "$zsh_check" == *"/usr/bin/zsh"* &&
        -n "$ghostty_check" &&
        -n "$starship_check" &&
        -n "$firacode_check" &&
        -n "$eza_check" &&
        -n "$fzf_check"
    ]]; then
        array[modern_terminal]=$installed
    else
        array[modern_terminal]=$not_installed
    fi

    if [[ "$dracula_theme_check" == *"Dracula"* ]]; then
        array[dracula_theme]=$installed
    else
        array[dracula_theme]=$not_installed
    fi

    if [[ -n "$vscode_check" ]]; then
        array[vscode]=$installed
    else
        array[vscode]=$not_installed
    fi

    if [[ "$flatpak_apps_check" == *"insomnia"* ]]; then
        array[insomnia]=$installed
    else
        array[insomnia]=$not_installed
    fi

    if [[ -n "$dbeaver_check" ]]; then
        array[dbeaver]=$installed
    else
        array[dbeaver]=$not_installed
    fi

    if [[ "$flatpak_apps_check" == *"obsidian"* ]]; then
        array[obsidian]=$installed
    else
        array[obsidian]=$not_installed
    fi
    if [[ "$flatpak_apps_check" == *"discord"* ]]; then
        array[discord]=$installed
    else
        array[discord]=$not_installed
    fi

    if [[ "$flatpak_apps_check" == *"telegram"* ]]; then
        array[telegram]=$installed
    else
        array[telegram]=$not_installed
    fi
}

checks
to_install=$(zenity --list \
    --checklist \
    --width 350 \
    --height 510 \
    --title "Apps Installer" \
    --text "<b>Choose apps to install</b>" \
    --column "" --column "Apps" --column "Installed?"\
    False "Docker" "${array[docker]}" \
    False "Git" "${array[git]}" \
    False "Node" "${array[node]}" \
    False "Claude Code" "${array[claude]}" \
    False "Modern Terminal" "${array[modern_terminal]}" \
    False "Dracula Theme" "${array[dracula_theme]}" \
    False "VS Code" "${array[vscode]}" \
    False "Insomnia" "${array[insomnia]}" \
    False "DBeaver" "${array[dbeaver]}" \
    False "Obsidian" "${array[obsidian]}" \
    False "Discord" "${array[discord]}" \
    False "Telegram" "${array[telegram]}" \
    False "Remove Junk Apps" "" \
)

if [[ "$to_install" == *"Docker"* ]]; then
    bash src/docker.sh
fi
if [[ "$to_install" == *"Git"* ]]; then
    bash src/git.sh
fi
if [[ "$to_install" == *"Node"* ]]; then
    bash src/node.sh
fi
if [[ "$to_install" == *"Claude Code"* ]]; then
    bash src/claude.sh
fi
if [[ "$to_install" == *"Modern Terminal"* ]]; then
    bash src/modern-terminal.sh
fi
if [[ "$to_install" == *"Dracula Theme"* ]]; then
    bash src/dracula-theme.sh
fi
if [[ "$to_install" == *"VS Code"* ]]; then
    bash src/vscode.sh
fi
if [[ "$to_install" == *"Insomnia"* ]]; then
    bash src/insomnia.sh
fi
if [[ "$to_install" == *"DBeaver"* ]]; then
    bash src/dbeaver.sh
fi
if [[ "$to_install" == *"Obsidian"* ]]; then
    bash src/obsidian.sh
fi
if [[ "$to_install" == *"Discord"* ]]; then
    bash src/discord.sh
fi
if [[ "$to_install" == *"Telegram"* ]]; then
    bash src/telegram.sh
fi
if [[ "$to_install" == *"Remove Junk Apps"* ]]; then
    bash src/remove-junk-apps.sh
fi

bash src/default-pack.sh
