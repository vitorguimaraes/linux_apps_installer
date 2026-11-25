#!/usr/bin/env bash
# Setup: Ghostty + zsh + Starship (prompt minimalista, tema Dracula) + Ctrl+Alt+T
# Uso: bash setup-ghostty.sh
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
sudo apt install -y zsh zsh-autosuggestions zsh-syntax-highlighting eza bat ripgrep micro fzf curl unzip fontconfig
command -v ghostty >/dev/null || sudo snap install ghostty --classic
command -v starship >/dev/null || sudo apt install -y starship

# --- 2) FiraCode Nerd Font ---
if ! fc-list | grep -qi "FiraCode Nerd"; then
  log "Instalando FiraCode Nerd Font"
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT   # também limpa se o curl ou o unzip falharem
  curl -fL -o "$tmp/FiraCode.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
  mkdir -p ~/.local/share/fonts/FiraCode
  unzip -oq "$tmp/FiraCode.zip" -d ~/.local/share/fonts/FiraCode
  fc-cache -f
fi

# --- 3) zsh ---
log "Configurando ~/.zshrc e aliases"

BLOCK_BEGIN='# >>> modern-terminal >>>'
BLOCK_END='# <<< modern-terminal <<<'

# Grava o conteúdo (stdin) em um bloco delimitado dentro de $1, sem tocar no resto do arquivo.
# Se o bloco já existe, é substituído no mesmo lugar; senão é adicionado ao final.
upsert_block() {
  local file=$1 blk; blk=$(mktemp)
  { echo "$BLOCK_BEGIN"; cat; echo "$BLOCK_END"; } > "$blk"
  touch "$file"
  if grep -qxF "$BLOCK_BEGIN" "$file"; then
    local out; out=$(mktemp)
    awk -v b="$BLOCK_BEGIN" -v e="$BLOCK_END" 'FNR==NR{blk=blk $0 "\n"; next}
      $0==b{printf "%s", blk; skip=1; next} skip&&$0==e{skip=0; next} !skip' "$blk" "$file" > "$out"
    cat "$out" > "$file"; rm -f "$out"
  else
    # Se a última linha não termina em quebra de linha, o marcador grudaria nela e o bloco nunca seria reconhecido
    [ -s "$file" ] && [ -n "$(tail -c1 "$file")" ] && echo >> "$file"
    cat "$blk" >> "$file"
  fi
  rm -f "$blk"
}

# Primeira execução: o .zshrc antigo (Powerlevel10k etc.) conflita com o Starship.
# Começa limpo, mas preserva as linhas do nvm (adicionadas por src/node.sh). O backup fica em ~/.zshrc.bak.*
if [ -f ~/.zshrc ] && ! grep -qxF "$BLOCK_BEGIN" ~/.zshrc; then
  nvm_lines=$(grep -i 'nvm' ~/.zshrc || true)
  : > ~/.zshrc
  [ -n "$nvm_lines" ] && printf '%s\n' "$nvm_lines" >> ~/.zshrc
fi

upsert_block ~/.zshrc <<'EOF'
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
# Cores do eza por extensão (códigos ANSI; o tema do Ghostty define o tom de cada cor)
export EZA_COLORS="di=90;4:Dockerfile=36:*.css=36:*.jsx=36:*.c=36:*.cpp=36:*.go=36:*.py=36:*.exs=34:*.ex=34:*.php=34:*.html=31:*.rb=31:*.js=33:*.java=33:*.yml=35:*.yaml=35:*.lock=32:*.sh=32:*.zsh=32:*.bash*=32:*.zshrc=32:*.tar=32:*.gz=32:*.zip=32:*.rar=32:*.tar.gz=32:*.tar.xz=32"
[ -f ~/.bash_aliases ] && source ~/.bash_aliases

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6272a4'
export FZF_DEFAULT_OPTS="--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9,fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9,info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6,marker:#ff79c6,spinner:#ffb86c,header:#6272a4"
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source <(fzf --zsh)  # Ctrl+R (histórico), Ctrl+T (arquivos), Alt+C (cd)
eval "$(starship init zsh)"
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh  # sempre por último
EOF

upsert_block ~/.bash_aliases <<'EOF'
alias ls="eza --icons -lh"
alias lt="eza --icons -lh --tree --level=2"
alias ll="eza --icons -lha"
alias cat="batcat"
alias udp="sudo apt update && sudo apt upgrade && sudo apt autoremove -y"
alias grep="rg"
alias nano="micro"
EOF

# sudo (já autenticado pelo apt) evita pedir a senha de novo; se falhar, só avisa e segue configurando
if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]; then
  sudo chsh -s "$(command -v zsh)" "$USER" \
    || echo "  AVISO: não consegui trocar o shell padrão. Rode depois: chsh -s $(command -v zsh)"
fi

# --- 4) Ghostty ---
log "Configurando Ghostty (Dracula)"
mkdir -p ~/.config/ghostty
# "|| true": sem nenhuma correspondência o grep sai com 1 e o pipefail encerraria o script; o fallback abaixo cobre o caso vazio
FONT=$(fc-list : family | grep -i "FiraCode Nerd Font" | grep -vi -e mono -e propo | head -1 | cut -d, -f1) || true
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

# --- 5) Starship (prompt minimalista colorido, paleta Dracula) ---
log "Configurando Starship (Dracula)"
mkdir -p ~/.config
cat > ~/.config/starship.toml <<'EOF'
"$schema" = 'https://starship.rs/config-schema.json'

palette = 'dracula'
add_newline = false
format = "$directory$git_branch$git_status$cmd_duration$line_break$character"

[directory]
style = 'bold purple'
truncation_length = 3
truncate_to_repo = false
truncation_symbol = '…/'
format = '[$path]($style)[$read_only]($read_only_style) '

[git_branch]
symbol = ' '
style = 'pink'
format = '[$symbol$branch]($style) '

[git_status]
style = 'yellow'
up_to_date = '[✓](green)'
format = '([$all_status$ahead_behind]($style) )'

[cmd_duration]
min_time = 3000
style = 'comment'
format = '[took $duration]($style) '

[character]
success_symbol = '[❯](bold green)'
error_symbol = '[❯](bold red)'

[palettes.dracula]
red = '#ff5555'
orange = '#ffb86c'
yellow = '#f1fa8c'
green = '#50fa7b'
cyan = '#8be9fd'
purple = '#bd93f9'
pink = '#ff79c6'
comment = '#6272a4'
foreground = '#f8f8f2'
background = '#282a36'
EOF

# --- 6) micro com Dracula ---
micro -option colorscheme dracula-tc >/dev/null 2>&1 || true

# --- 7) Ctrl+Alt+T -> Ghostty (preserva atalhos existentes) ---
log "Configurando atalho Ctrl+Alt+T"
MK=org.gnome.settings-daemon.plugins.media-keys
KEY=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ghostty/
if gsettings get $MK custom-keybindings >/dev/null 2>&1; then
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
else
  echo "  AVISO: nenhuma sessão GNOME encontrada, o atalho Ctrl+Alt+T não foi configurado. Rode o script de novo dentro da sessão."
  log "Pronto! Faça logout/login e abra o Ghostty pelo menu de aplicativos."
fi
