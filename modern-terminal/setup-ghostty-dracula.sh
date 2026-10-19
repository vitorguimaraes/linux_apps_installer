#!/usr/bin/env bash
# Setup: Ghostty + zsh + Starship (catppuccin-powerline com paleta Dracula) + Ctrl+Alt+T
# Uso: bash setup-ghostty-dracula.sh
set -euo pipefail

log() { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }

# --- 0) Backup ---
log "Backup das configs atuais"
ts=$(date +%Y%m%d-%H%M%S)
for f in ~/.zshrc ~/.bash_aliases ~/.config/ghostty/config.ghostty ~/.config/ghostty/config ~/.config/starship.toml; do
  [ -f "$f" ] && cp "$f" "$f.bak.$ts" && echo "  $f -> $f.bak.$ts"
done
rm -f ~/.config/ghostty/config

# --- 1) Pacotes ---
log "Instalando pacotes"
sudo apt update
sudo apt install -y zsh zsh-autosuggestions zsh-syntax-highlighting eza bat ripgrep micro curl unzip fontconfig
command -v ghostty >/dev/null || sudo snap install ghostty --classic
command -v starship >/dev/null || curl -sS https://starship.rs/install.sh | sh -s -- -y

# --- 2) FiraCode Nerd Font ---
if ! fc-list | grep -qi "FiraCode Nerd"; then
  log "Instalando FiraCode Nerd Font"
  tmp=$(mktemp -d)
  curl -fL -o "$tmp/FiraCode.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
  mkdir -p ~/.local/share/fonts/FiraCode
  unzip -oq "$tmp/FiraCode.zip" -d ~/.local/share/fonts/FiraCode
  fc-cache -f
  rm -rf "$tmp"
fi

# --- 3) zsh ---
log "Configurando ~/.zshrc e aliases"
cat > ~/.zshrc <<'EOF'
setopt interactivecomments histignorealldups sharehistory
bindkey -e
HISTSIZE=10000; SAVEHIST=10000; HISTFILE=~/.zsh_history

autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export BAT_THEME="Dracula"
[ -f ~/.bash_aliases ] && source ~/.bash_aliases

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6272a4'
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
eval "$(starship init zsh)"
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh  # sempre por último
EOF

cat > ~/.bash_aliases <<'EOF'
alias ls="eza --icons -lh"
alias lt="eza --icons -lh --tree --level=2"
alias ll="eza --icons -lha"
alias cat="batcat"
alias udp="sudo apt update && sudo apt upgrade && sudo apt autoremove -y"
alias grep="rg"
alias nano="micro"
EOF

[ "$(getent passwd "$USER" | cut -d: -f7)" = "$(command -v zsh)" ] || chsh -s "$(command -v zsh)"

# --- 4) Ghostty ---
log "Configurando Ghostty (Dracula)"
mkdir -p ~/.config/ghostty
FONT=$(fc-list : family | grep -i "FiraCode Nerd Font" | grep -vi -e mono -e propo | head -1 | cut -d, -f1)
cat > ~/.config/ghostty/config.ghostty <<EOF
theme = Dracula
font-family = ${FONT:-FiraCode Nerd Font}
font-size = 13
cursor-style = block
cursor-style-blink = true
window-padding-x = 14
window-padding-y = 12
EOF
ghostty +validate-config || echo "  AVISO: confira o nome do tema com: ghostty +list-themes | grep -i dracula"

# --- 5) Starship (catppuccin-powerline + paleta Dracula) ---
log "Configurando Starship (Dracula)"
mkdir -p ~/.config
starship preset catppuccin-powerline -o ~/.config/starship.toml
sed -i "s/^palette = .*/palette = 'dracula'/" ~/.config/starship.toml
cat >> ~/.config/starship.toml <<'EOF'

[palettes.dracula]
red = '#ff5555'
maroon = '#ff5555'
peach = '#ffb86c'
yellow = '#f1fa8c'
green = '#50fa7b'
teal = '#8be9fd'
sky = '#8be9fd'
sapphire = '#8be9fd'
blue = '#bd93f9'
lavender = '#bd93f9'
mauve = '#bd93f9'
pink = '#ff79c6'
flamingo = '#ff79c6'
rosewater = '#ff79c6'
text = '#f8f8f2'
subtext1 = '#f8f8f2'
subtext0 = '#e2e2dc'
overlay2 = '#6272a4'
overlay1 = '#6272a4'
overlay0 = '#6272a4'
surface2 = '#44475a'
surface1 = '#44475a'
surface0 = '#44475a'
base = '#282a36'
mantle = '#21222c'
crust = '#282a36'
EOF

# --- 6) micro com Dracula ---
micro -option colorscheme dracula-tc >/dev/null 2>&1 || true

# --- 7) Ctrl+Alt+T -> Ghostty (preserva atalhos existentes) ---
log "Configurando atalho Ctrl+Alt+T"
MK=org.gnome.settings-daemon.plugins.media-keys
KEY=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ghostty/
gsettings set $MK terminal "[]"
cur=$(gsettings get $MK custom-keybindings)
if [[ "$cur" != *"$KEY"* ]]; then
  if [[ "$cur" == "@as []" || "$cur" == "[]" ]]; then
    new="['$KEY']"
  else
    new="${cur%]}, '$KEY']"
  fi
  gsettings set $MK custom-keybindings "$new"
fi
S="$MK.custom-keybinding:$KEY"
gsettings set "$S" name 'Ghostty'
gsettings set "$S" command "$(command -v ghostty || echo /snap/bin/ghostty)"
gsettings set "$S" binding '<Primary><Alt>t'

log "Pronto! Faça logout/login e abra o Ghostty com Ctrl+Alt+T."
