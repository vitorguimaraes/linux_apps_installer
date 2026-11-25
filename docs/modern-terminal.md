# Modern Terminal

Instalado por `src/modern-terminal.sh`, que executa `modern-terminal/setup-ghostty.sh`.
Tudo usa o tema **Dracula** e a fonte **FiraCode Nerd Font**.

Para ver os estilos de prompt e todas as opções de personalização, abra [`terminal-customization.html`](terminal-customization.html) no navegador.
A aba **Laboratório** da mesma página ([`#lab`](terminal-customization.html#lab)) monta o prompt e testa comandos num terminal simulado.

## Ferramentas

| Ferramenta | Para que serve | Como usar |
|---|---|---|
| **Ghostty** | Emulador de terminal rápido (renderização por GPU). Substitui o Hyper. | `Ctrl+Alt+T` abre o terminal. Config em `~/.config/ghostty/config.ghostty`. |
| **zsh** | Shell com completar melhor que o bash. Vira o shell padrão (`chsh`). | Faça logout/login para valer. `Tab` completa e abre menu de seleção. |
| **Starship** | Prompt (a linha antes do cursor): mostra pasta, branch do git, versões de linguagens, etc. Substitui o Powerlevel10k. | Automático. Config em `~/.config/starship.toml`. |
| **eza** | `ls` moderno: cores, ícones, árvore, status do git. Substitui o `exa` (sem manutenção). | `ls`, `ll`, `lt` (aliases abaixo) ou `eza --git -l`. |
| **bat** | `cat` com syntax highlight e números de linha. No Ubuntu o binário se chama `batcat`. | `cat arquivo.py` (alias) ou `batcat -A arquivo` para ver caracteres ocultos. |
| **ripgrep (`rg`)** | Busca texto em arquivos de forma recursiva e muito rápida, respeitando o `.gitignore`. | `rg "texto"`, `rg -i "texto" src/`, `rg -t py "def "`. |
| **micro** | Editor de terminal simples, com atalhos comuns (`Ctrl+S`, `Ctrl+Q`, `Ctrl+C/V`). Substitui o `nano`. | `nano arquivo` (alias) ou `micro arquivo`. |
| **fzf** | Busca difusa interativa em listas (histórico, arquivos, pastas). | `Ctrl+R` busca no histórico, `Ctrl+T` insere um arquivo, `Alt+C` entra em uma pasta. Também: `comando \| fzf`. |
| **zsh-autosuggestions** | Sugere em cinza o comando com base no histórico. | `→` (seta direita) aceita a sugestão. |
| **zsh-syntax-highlighting** | Colore o comando enquanto você digita: verde se existe, vermelho se não. | Automático. |
| **FiraCode Nerd Font** | Fonte com ligaduras e os ícones usados pelo Starship e pelo eza. | Definida no Ghostty. |

## Aliases (`~/.bash_aliases`)

| Alias | Comando | Efeito |
|---|---|---|
| `ls` | `eza --icons -lh` | Lista detalhada, tamanhos legíveis, com ícones |
| `ll` | `eza --icons -lha` | Igual ao `ls`, incluindo arquivos ocultos |
| `lt` | `eza --icons -lh --tree --level=2` | Árvore de diretórios com 2 níveis |
| `cat` | `batcat` | Mostra arquivo com cores |
| `grep` | `rg` | Busca com ripgrep |
| `nano` | `micro` | Abre o micro |
| `udp` | `sudo apt update && sudo apt upgrade && sudo apt autoremove -y` | Atualiza o sistema |

Os aliases só valem no terminal interativo. Scripts continuam usando o `grep`, `cat` e `nano` originais.
Para ignorar um alias uma vez, use `\grep` ou `command cat`.

Atenção com `grep` → `rg`: o `rg` é recursivo por padrão e as opções diferem em alguns pontos
(por exemplo, `rg -r` é "replace" e não "recursivo").

## O que mudou em relação à instalação com Hyper

| Item | Antes | Agora |
|---|---|---|
| Terminal | Hyper (Electron, `.deb`) | **Ghostty** (snap, versão 1.4.0) |
| Prompt | Powerlevel10k (git clone + `.p10k.zsh`) | **Starship** (prompt minimalista: pasta, branch e `❯`, paleta Dracula) |
| `ls` | `exa` (compilado com `cargo`, demorava) | **eza** (pacote apt) |
| Plugins zsh | Cópias dentro do repositório | Pacotes apt (`zsh-autosuggestions`, `zsh-syntax-highlighting`) |
| Rust/cargo | Instalado só para compilar o exa | Não é mais instalado |
| fzf | Clonado do GitHub e instalado com `install` | Pacote apt, ativado com `source <(fzf --zsh)` |
| Histórico do zsh | 100 linhas | 10 000 linhas |
| Cores do tema | Hyper preto/branco | Dracula no Ghostty, bat, micro e Starship |
| Cores do `ls` | `EXA_COLORS` por extensão | Mesmas cores em `EZA_COLORS` (veja abaixo) |
| Atalho de terminal | Via `update-alternatives` / xfce | `Ctrl+Alt+T` no GNOME (`gsettings`) |
| Backup | Nenhum, sobrescrevia os arquivos | Backup `*.bak.<data>` de `.zshrc`, `.bash_aliases` e configs |

Ferramentas que continuam iguais: zsh, bat, ripgrep, micro, fzf e os plugins do zsh (mudou só a forma de instalar).

## Cores do `ls` (`EZA_COLORS`)

Valores herdados do `EXA_COLORS` antigo. São códigos ANSI, e o tema Dracula do Ghostty define o tom exato de cada um.

| Código | Cor | Arquivos |
|---|---|---|
| `90;4` | cinza sublinhado | diretórios |
| `36` | ciano | `Dockerfile`, `.css`, `.jsx`, `.c`, `.cpp`, `.go`, `.py` |
| `34` | azul | `.ex`, `.exs`, `.php` |
| `33` | amarelo | `.js`, `.java` |
| `31` | vermelho | `.html`, `.rb` |
| `35` | magenta | `.yml`, `.yaml` |
| `32` | verde | `.lock`, `.sh`, `.zsh`, `.bash*`, `.zshrc`, `.tar`, `.gz`, `.zip`, `.rar`, `.tar.gz`, `.tar.xz` |

O valor antigo repetia `.js` (34 e depois 33) e `.java` (31 e depois 33). No eza vale a última ocorrência, então ficou amarelo.
Para ajustar, edite a linha `export EZA_COLORS=...` no `~/.zshrc`. Cores exatas também funcionam,
por exemplo `*.py=38;2;139;233;253` (RGB do ciano Dracula).

## Como o `~/.zshrc` e o `~/.bash_aliases` são gerenciados

O setup **não sobrescreve** esses arquivos. Ele grava só o trecho entre `# >>> modern-terminal >>>` e
`# <<< modern-terminal <<<`. Em novas execuções, apenas esse trecho é atualizado. O que você
(ou outro script, como o `src/node.sh` com o nvm) escreveu fora do trecho é mantido.

Na primeira execução, o `.zshrc` antigo (Powerlevel10k etc.) é descartado, porque conflita com o Starship,
e as linhas do nvm são preservadas. O backup completo fica em `~/.zshrc.bak.<data>`.
O Modern Terminal pode ser instalado antes ou depois do Node.

## Pontos de atenção

- **Faça logout/login** depois de instalar para o zsh virar o shell padrão e o `Ctrl+Alt+T` valer.

## Prompt (Starship)

Duas linhas: pasta em roxo, branch em rosa, `✓` verde quando a branch está sincronizada com o remoto,
flags em amarelo quando há alterações, tempo de comandos acima de 3 s em cinza, e `❯` verde
(vermelho se o último comando falhou). A configuração fica em `~/.config/starship.toml` e é regerada a cada execução do setup.
