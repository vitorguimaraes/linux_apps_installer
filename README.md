# Linux Apps Installer

Conjunto de scripts Bash que **configura um Ubuntu (GNOME) do zero**: instala as ferramentas de
desenvolvimento e os aplicativos do dia a dia, aplica o tema Dracula, remove programas que não são usados
e deixa atalhos de teclado, fontes e extensões do GNOME prontos.

Você roda um único comando, escolhe o que quer em uma janela de seleção (zenity) e o script faz o resto.

---

## Sumário

- [Início rápido](#início-rápido)
- [Requisitos](#requisitos)
- [Como funciona](#como-funciona)
- [O que cada opção do menu faz](#o-que-cada-opção-do-menu-faz)
- [Pacote padrão (`default-pack`)](#pacote-padrão-default-pack)
- [Atalhos de teclado configurados](#atalhos-de-teclado-configurados)
- [Modern Terminal em detalhes](#modern-terminal-em-detalhes)
- [Claude Code e statusline em detalhes](#claude-code-e-statusline-em-detalhes)
- [Tema Dracula em detalhes](#tema-dracula-em-detalhes)
- [Remove Junk Apps](#remove-junk-apps)
- [Script que não está no menu](#script-que-não-está-no-menu)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Arquivos que o projeto altera na sua máquina](#arquivos-que-o-projeto-altera-na-sua-máquina)
- [Como adicionar um novo app](#como-adicionar-um-novo-app)
- [Limitações e pontos de atenção](#limitações-e-pontos-de-atenção)
- [Solução de problemas](#solução-de-problemas)

---

## Início rápido

```bash
git clone <url-do-repositorio> linux_apps_installer
cd linux_apps_installer
bash main.sh
```

1. Abre uma janela com a lista de apps e a coluna **Installed?** (já instalado ou não).
2. Marque o que deseja e confirme.
3. Cada app marcado é instalado em sequência (o `sudo` pede a senha quando necessário).
4. No fim, o [pacote padrão](#pacote-padrão-default-pack) **sempre** é executado.
5. **Faça logout/login (ou reinicie)** ao terminar. Isso é necessário para o `zsh` virar o shell padrão, para o grupo
   `docker` valer e para as extensões do GNOME serem carregadas.

> **Pode rodar de qualquer pasta.** O `main.sh` e os instaladores resolvem os caminhos a partir do próprio local,
> então `bash /caminho/do/projeto/main.sh` funciona igual a entrar na pasta e rodar `bash main.sh`.

---

## Requisitos

| Requisito | Detalhe |
|---|---|
| Sistema | Ubuntu com **GNOME** (desenvolvido e usado no Ubuntu 26.04, GNOME 50, Wayland). Os scripts usam `gsettings`, extensões do GNOME e `apt`. |
| Arquitetura | **amd64** (x86_64). Chrome, VS Code e Docker são baixados para essa arquitetura. |
| Usuário | Conta com permissão de `sudo`. |
| Internet | Necessária: pacotes `apt`, repositórios de terceiros, Flathub, GitHub. |
| Sessão gráfica | O menu usa `zenity`, então precisa rodar dentro de uma sessão desktop. |
| Pacotes de base | `wget`, `curl`, `unzip`, `git`. O `main.sh` instala sozinho o **zenity** (que já vem no Ubuntu desktop) e o **Flatpak**, se não existirem. |

---

## Como funciona

```
main.sh
 ├─ instala o zenity e o Flatpak se faltarem, e sempre garante o remote Flathub
 ├─ checks(): detecta o que já está instalado (dpkg, whereis, command -v, flatpak list, gsettings)
 ├─ zenity --checklist: mostra o menu com a coluna "Installed?"
 ├─ para cada item marcado → bash src/<app>.sh
 └─ sempre ao final → bash src/default-pack.sh
```

- **`main.sh`** é o orquestrador. A função `checks()` preenche o estado de cada app, e o `zenity` apresenta a lista.
  O status é só informativo: você pode marcar um app que já está instalado para reinstalar/reaplicar a configuração.
- **`src/*.sh`** são os instaladores, **um por app**. Cada um é independente e pode ser executado sozinho
  (`bash src/docker.sh`), de qualquer pasta.
- Quando um instalador precisa de outro, ele o chama. Por exemplo, `node.sh` e `obsidian.sh` instalam o Git antes,
  se necessário.
- **Todos** os instaladores são **idempotentes**: podem ser executados de novo sem duplicar configuração. Os aliases do
  Git que você já mudou são mantidos, as linhas do nvm entram uma vez só, o ícone no dock não se repete e o cofre do
  Obsidian que já foi clonado não é tocado.
- Quando algo falha, o instalador em geral **sai com código diferente de zero** e uma mensagem. O `main.sh` segue com os
  próximos itens; corrija a causa e reexecute só o que falhou.

---

## O que cada opção do menu faz

| Opção | Script | Como instala | O que faz |
|---|---|---|---|
| **Docker** | `src/docker.sh` | Repositório oficial da Docker (`apt`) | Adiciona a chave GPG e o repositório oficial, instala `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin` e `docker-compose-plugin`. Roda `hello-world` para validar. Cria `~/.docker/config.json` com um formato customizado para `docker ps` (só se você ainda não tiver o arquivo). Adiciona seu usuário ao grupo `docker` (efeito após novo login). |
| **Git** | `src/git.sh` | PPA `git-core/ppa` | Instala a versão mais recente do Git e cria os aliases globais `br` (branch), `sw` (switch), `st` (status), `cm` (commit), `ps` (push) e `pu` (pull). |
| **Node** | `src/node.sh` | [nvm](https://github.com/nvm-sh/nvm) (clone da última tag) | Instala o nvm em `~/.nvm`, adiciona o carregamento dele ao `~/.bashrc` e `~/.zshrc` e instala o Node.js mais recente (`nvm install node`). Instala o Git antes, se faltar. |
| **Claude Code** | `src/claude.sh` | Instalador nativo oficial (`claude.ai/install.sh`) | Instala o Claude Code (se faltar) e uma statusline em Powerline com cores Dracula, em script bash. [Detalhes abaixo](#claude-code-e-statusline-em-detalhes). |
| **Modern Terminal** | `src/modern-terminal.sh` → `modern-terminal/setup-ghostty.sh` | `apt`, `snap`, GitHub | Ghostty + zsh + Starship + eza + fzf + FiraCode Nerd Font, tudo com tema Dracula. [Detalhes abaixo](#modern-terminal-em-detalhes). |
| **Dracula Theme** | `src/dracula-theme.sh` | GitHub (zip do tema) | Tema GTK/GNOME Shell Dracula, cor de destaque roxa e ícones Yaru-magenta. [Detalhes abaixo](#tema-dracula-em-detalhes). |
| **VS Code** | `src/vscode.sh` | Repositório oficial da Microsoft (`apt`) | Instala o `code`. Como vem de um repositório `apt`, o `apt upgrade` mantém o VS Code atualizado. |
| **Insomnia** | `src/insomnia.sh` | Flatpak (`rest.insomnia.Insomnia`) | Cliente de APIs REST/GraphQL. Fixado no dock. |
| **DBeaver** | `src/dbeaver.sh` | Repositório oficial do DBeaver (`apt`) | Instala o `dbeaver-ce` (Community) a partir do repositório do próprio projeto, que é mais atual que o do Flathub, e o fixa no dock. |
| **Obsidian** | `src/obsidian.sh` | Flatpak (`md.obsidian.Obsidian`) | Instala o Obsidian, fixa no dock e **clona o seu cofre** (`vitorguimaraes/ObsidianVault`) em `~/.ObsidianVault`. |
| **Discord** | `src/discord.sh` | Flatpak (`com.discordapp.Discord`) | Instala o Discord e fixa no dock. |
| **Telegram** | `src/telegram.sh` | Flatpak (`org.telegram.desktop`) | Instala o Telegram Desktop e fixa no dock. |
| **Remove Junk Apps** | `src/remove-junk-apps.sh` | `apt purge` | Remove pacotes `apt` que você não usa, **mostrando a lista e pedindo confirmação antes**. [Detalhes abaixo](#remove-junk-apps). |

### Como o menu detecta o que já está instalado

| App | Critério usado na coluna "Installed?" |
|---|---|
| Docker | `docker-ce` **e** `docker-compose-plugin` instalados via `dpkg` |
| Git | `whereis git` encontra `/usr/bin/git` |
| Node | `whereis node` encontra um caminho com `versions/node/` (instalação via nvm) |
| Claude Code | `claude` encontrado, `statusLine` do `~/.claude/settings.json` apontando para `~/.claude/statusline.sh` e esse script executável |
| Modern Terminal | `zsh`, `ghostty`, `starship`, `eza`, `fzf` e a fonte FiraCode Nerd presentes |
| Dracula Theme | `gtk-theme` do GNOME contém "Dracula" |
| VS Code | pacote `code` instalado via `dpkg` |
| DBeaver | pacote `dbeaver-ce` instalado via `dpkg` |
| Insomnia, Obsidian, Discord, Telegram | presença do nome em `flatpak list` |

---

## Pacote padrão (`default-pack`)

`src/default-pack.sh` **roda sempre**, depois dos itens marcados, mesmo que você não marque nada.
Ele representa a configuração básica de qualquer máquina:

**Sistema e GNOME**

- Instala o Git pelo PPA (`src/git.sh`) **somente se ele ainda não existir**. Para atualizar o Git, use a opção **Git** do menu.
- Instala o **Extension Manager** (`gnome-shell-extension-manager`) para você instalar a extensão **Dash to Panel**
  (abra o Extension Manager, aba *Browse*, e busque por *Dash to Panel*).
- Instala o `dconf-editor`.
- Instala a fonte **Poppins** (copia os `.ttf` de `Poppins/` para `~/.local/share/fonts` e atualiza o cache de fontes).
- Ativa a **luz noturna** com temperatura de 2700 K, praticamente o dia todo (das 22:00 às 21:58).
- Força o esquema de cores escuro (`prefer-dark`).
- Oculta a pasta `snap` na pasta pessoal (adiciona `snap` ao `~/.hidden`, uma única vez).

**Aplicativos instalados**

| App | Origem |
|---|---|
| Google Chrome | `.deb` oficial (`src/chrome.sh`) |
| Flameshot (capturas de tela) | `apt` |
| qBittorrent | Flatpak |
| VLC | Flatpak |
| SimpleScreenRecorder | `apt` |
| `fd-find` (`fdfind`) | `apt` |
| `bat` (`batcat`) | `apt` |
| `ripgrep` (`rg`) | `apt` |
| `micro` | `apt` |
| `bashtop` | `apt` (repositório do Ubuntu) |
| `tldr` | `npm install -g tldr` (instala o Node antes, se faltar) |

Os pacotes `apt` são instalados em um único comando e o `apt` ignora os que já existem. O Chrome, os apps
Flatpak e o `tldr` só são instalados se ainda não estiverem presentes. Rodar o pacote de novo é seguro.

Os passos de instalação são independentes: se algum falhar (rede, por exemplo), os demais e as configurações do GNOME
continuam, e no fim o `default-pack` lista o que falhou e sai com código 1. Sem sessão GNOME, ele avisa e sai antes de
alterar qualquer coisa.

---

## Atalhos de teclado configurados

Definidos pelo `default-pack` (e o de terminal pelo Modern Terminal), via `gsettings`. Os atalhos são **somados** aos que você
já tem; nenhum atalho personalizado existente é apagado.

| Atalho | Ação |
|---|---|
| `Ctrl+Alt+T` | Abre o **Ghostty** (configurado pelo Modern Terminal) |
| `Print` | **Flameshot** (`flameshot gui`) |
| `Super+V` | **VS Code** |
| `Super+B` | **DBeaver** |
| `Super+I` | **Insomnia** |
| `Super+O` | **Obsidian** |
| `Super+D` | **Discord** |
| `Super+C` | Calculadora |
| `Super+F` | Navegador padrão (tecla "www") |

**Atalhos padrão do GNOME que são desativados** (para não conflitarem com o Flameshot e com o VS Code):

- Captura de tela do GNOME (`screenshot`, `screenshot-window`, `show-screenshot-ui`, `show-screen-recording-ui`).
- Bandeja de mensagens e visão geral de aplicativos (`toggle-message-tray`, `toggle-application-view`).
- Mover janela para a área de trabalho acima/abaixo (conflitava com "copiar linha" do VS Code).

---

## Modern Terminal em detalhes

Instalado por `src/modern-terminal.sh`, que executa `modern-terminal/setup-ghostty.sh`.
Documentação completa em [`docs/modern-terminal.md`](docs/modern-terminal.md); um guia visual de personalização com
laboratório interativo está em [`docs/terminal-customization.html`](docs/terminal-customization.html), e abre
sozinho no navegador ao fim da instalação.

**O que é instalado**

| Ferramenta | Função |
|---|---|
| **Ghostty** (snap) | Emulador de terminal rápido, com renderização por GPU |
| **zsh** | Shell com completar melhor; vira o shell padrão (`chsh`) |
| **Starship** | Prompt minimalista: pasta, branch do git e `❯`, com paleta Dracula |
| **eza** | `ls` moderno, com cores e ícones |
| **bat** | `cat` com *syntax highlight* |
| **ripgrep** | `grep` recursivo e rápido |
| **micro** | Editor de terminal simples (substitui o `nano`) |
| **fzf** | Busca difusa: `Ctrl+R` (histórico), `Ctrl+T` (arquivos), `Alt+C` (pastas) |
| **zsh-autosuggestions** | Sugestão em cinza baseada no histórico (aceite com `→`) |
| **zsh-syntax-highlighting** | Colore o comando enquanto você digita |
| **FiraCode Nerd Font** | Fonte com ligaduras e ícones (baixada do Nerd Fonts) |

**Aliases criados** (em `~/.bash_aliases`)

| Alias | Equivale a |
|---|---|
| `ls` | `eza --icons -lh` |
| `ll` | `eza --icons -lha` (inclui ocultos) |
| `lt` | `eza --icons -lh --tree --level=2` |
| `cat` | `batcat` |
| `grep` | `rg` |
| `nano` | `micro` |
| `udp` | `sudo apt update && sudo apt upgrade && sudo apt autoremove -y` |

**Como o script protege seus arquivos**

- Antes de tudo, faz **backup** de `~/.zshrc`, `~/.bash_aliases`, da config do Ghostty e do `starship.toml`
  como `<arquivo>.bak.<data-hora>`.
- Escreve **apenas dentro de um bloco delimitado** (`# >>> modern-terminal >>>` … `# <<< modern-terminal <<<`).
  Nas execuções seguintes só esse bloco é atualizado; o que estiver fora dele é mantido.
- Na **primeira** execução, o `.zshrc` antigo é descartado (configurações como Powerlevel10k conflitam com o Starship),
  mas as linhas do `nvm` são preservadas.
- O atalho `Ctrl+Alt+T` é **somado** aos atalhos personalizados que você já tinha, sem apagá-los.

---

## Claude Code e statusline em detalhes

Instalado por `src/claude.sh`. A statusline é a barra que o Claude Code mostra abaixo da caixa de entrada. Aqui ela é um
**script bash** (`claude/statusline.sh`, cerca de 50 linhas, só precisa de `jq`) em estilo **Powerline**, com as cores do
Dracula e uma cor de fundo por item. Não usa Node nem pacotes de terceiros:

```
 Sonnet 5.5   Thinking: high   Ctx Used: 42%   5h: ▓▓▓░░│░░░░ 27%   Weekly: 61% 
```

| Item | Campo que o Claude Code envia | Cor de fundo |
|---|---|---|
| Modelo | `model.display_name` | ciano `#8be9fd` |
| Esforço de raciocínio | `effort.level` | roxo `#bd93f9` |
| Contexto usado | `context_window.used_percentage` | laranja `#ffb86c` |
| Limite de 5 horas, com **marcador de tempo** | `rate_limits.five_hour.used_percentage` e `resets_at` | rosa `#ff79c6` |
| Limite semanal | `rate_limits.seven_day.used_percentage` | amarelo `#f1fa8c` |

No limite de 5 horas, o `▓` mostra quanto você já usou e o `│` mostra em que ponto da janela de 5 horas você está. Com o
preenchimento atrás do marcador, você está gastando menos do que o tempo permitiria; se o preenchimento passar do marcador,
está gastando mais rápido que o relógio. Os percentuais aparecem como números inteiros.

Um item que o Claude Code não enviou some junto com a seta dele. Os limites de uso só existem em contas **Pro ou Max**, depois
da primeira resposta da sessão, e o esforço de raciocínio só em modelos que o suportam.

**O que o instalador faz, em ordem**

1. **Claude Code:** se o comando `claude` não existir, baixa o instalador oficial (`https://claude.ai/install.sh`) para uma
   pasta temporária e o executa. Se já existir, não reinstala (ele se atualiza sozinho; para atualizar na hora, `claude update`).
2. **jq:** instala pelo `apt` se faltar.
3. **Script da statusline:** copia `claude/statusline.sh` para `~/.claude/statusline.sh`. Se o arquivo já existir com outro
   conteúdo (por exemplo, se você o editou), guarda um backup `statusline.sh.bak.<data-hora>` antes.
4. **Ativação:** grava `statusLine` em `~/.claude/settings.json` (`"command": "~/.claude/statusline.sh"`, `"padding": 0` e
   `"refreshInterval": 10`, este só em Claude Code 2.1.97 ou mais novo, e um valor seu é mantido). As outras chaves do arquivo
   são mantidas. Se já existir outro `statusLine`, ele é substituído, depois de um backup. Um JSON inválido no `settings.json`
   interrompe o passo sem alterar o arquivo.
5. **Teste:** renderiza a linha com dados de exemplo e mostra o resultado. Se não sair nada, o instalador termina com erro.

**Para mudar o visual,** edite `~/.claude/statusline.sh` (ou `claude/statusline.sh` aqui no projeto e rode a opção de novo).
As cores ficam no começo do script, na função `bg`, e os rótulos nas linhas de cada item. Rodar a opção **Claude Code** de novo
sobrescreve o script instalado com o do projeto, guardando um backup do que você tinha.

**Requisitos do visual:** o Powerline usa o glifo `U+E0B0` de fonte Nerd Font. O **Modern Terminal** instala a FiraCode Nerd Font
e a configura no Ghostty. Em outro terminal ou fonte, as setas aparecem como quadrados.

---

## Tema Dracula em detalhes

`src/dracula-theme.sh` instala o [tema GTK Dracula](https://github.com/dracula/gtk) **apenas para o seu usuário**
(em `~/.local/share/themes/Dracula`, sem `sudo` para o tema em si) e:

1. Baixa e extrai o tema, substituindo a instalação anterior (se o download ou a extração falharem, o tema que já estava
   instalado é mantido). Sem sessão GNOME, o script avisa e sai antes de alterar qualquer arquivo.
2. Libera a pasta de temas para apps **Flatpak** (`flatpak override --user --filesystem=...:ro`).
3. Aplica o tema em apps **GTK4/libadwaita**, que ignoram a opção `gtk-theme` e só leem `~/.config/gtk-4.0`.
   O script copia o `gtk.css` e o `gtk-dark.css` reescrevendo o caminho dos ícones, e aponta `assets` para a pasta
   certa do tema. Isso evita o bug em que os **botões de fechar/minimizar/maximizar das janelas sumiam**.
   Qualquer arquivo seu pré-existente é guardado como `.bak`.
4. Instala/ativa a extensão **User Themes** (`gnome-shell-extensions`) para o tema valer também no GNOME Shell.
5. Aplica via `gsettings`: tema GTK `Dracula`, esquema escuro, **cor de destaque roxa** e ícones **Yaru-magenta-dark**
   (o magenta é o mais próximo do roxo Dracula).
6. Aplica o tema do Shell (`user-theme`). Se a extensão ainda não estiver ativa, mostra o comando para rodar depois do
   próximo login.

---

## Remove Junk Apps

`src/remove-junk-apps.sh` remove programas que costumam vir instalados e não são usados neste setup.

**É projetado para ser seguro:**

- Mexe **apenas em pacotes `apt`**. Snaps (Firefox, atualizador de firmware etc.) e a pasta `~/snap` nunca são tocados.
- Ferramentas de acessibilidade e o Bluetooth são mantidos.
- Pacotes que não existem no repositório são ignorados (o `apt` abortaria tudo se encontrasse um nome desconhecido).
- Faz uma **simulação** (`apt-get -s purge`) e **lista exatamente o que será removido**. Só prossegue se você digitar `y`.
  Qualquer outra resposta cancela sem remover nada.
- Se nenhum desses pacotes estiver instalado, avisa e sai sem pedir confirmação.

**Categorias do que é removido:** jogos do GNOME (Mines, Sudoku, Mahjongg, Aisleriot, Quadrapassel...), Thunderbird,
Evolution, LibreOffice, GIMP, Totem, Rhythmbox, Shotwell, Pitivi, Remmina, Transmission, Brasero, Gedit, Mousepad, Emacs,
Evince, Pidgin, gnome-weather/maps/clocks/calendar/contacts/tour e similares.

Ao final executa `apt clean`, `apt autoremove` e `apt -f install`.

---

## Script que não está no menu

Este script existe no projeto, mas **não é chamado pelo `main.sh`**. Rode-o manualmente se quiser.

### `src/dev-icons.sh`: ícones de arquivos de desenvolvimento

Troca os ícones dos tipos de arquivo JavaScript, CSS, HTML, YAML, Dockerfile, MATLAB e scripts (arquivos da pasta
`DevIcons/`) e passa a reconhecer `Dockerfile`, `Dockerfile.*`, `*.dockerfile` e `Containerfile` como um tipo próprio.

- **Só para o seu usuário, sem `sudo`.** Os ícones vão para `~/.local/share/icons/Yaru/<tamanho>/mimetypes/` e a definição do
  tipo para `~/.local/share/mime/packages/dev-icons.xml`. Nada em `/usr` é alterado.
- Funciona com o tema de ícones **Yaru** e todas as suas variantes (como `Yaru-magenta-dark`, usada pelo tema Dracula).
- Pode rodar de qualquer pasta e quantas vezes quiser. Reinicie o gerenciador de arquivos depois (`nautilus -q`).

```bash
bash src/dev-icons.sh
```

Para desfazer (rode da raiz do projeto). Remove só os arquivos que o script copiou, sem apagar o que mais você tenha em
`~/.local/share/icons/Yaru`:

```bash
for icon in DevIcons/*.svg DevIcons/*.png; do
    find ~/.local/share/icons/Yaru -path '*/mimetypes/*' -name "$(basename "$icon")" -delete
done
find ~/.local/share/icons/Yaru -type d -empty -delete
rm ~/.local/share/mime/packages/dev-icons.xml
update-mime-database ~/.local/share/mime
```

---

## Estrutura do projeto

```
linux_apps_installer/
├── main.sh                          # Ponto de entrada: menu zenity + orquestração
├── src/                             # Um instalador por app
│   ├── default-pack.sh              #   Configuração base (sempre executada)
│   ├── docker.sh
│   ├── git.sh
│   ├── node.sh
│   ├── claude.sh                    #   Claude Code + statusline
│   ├── modern-terminal.sh           #   Wrapper do setup-ghostty.sh + verificação
│   ├── dracula-theme.sh
│   ├── vscode.sh
│   ├── dbeaver.sh
│   ├── insomnia.sh
│   ├── obsidian.sh
│   ├── discord.sh
│   ├── telegram.sh
│   ├── chrome.sh                    #   Usado pelo default-pack
│   ├── remove-junk-apps.sh
│   └── dev-icons.sh                 #   Fora do menu
├── claude/
│   └── statusline.sh                # Statusline do Claude Code (Powerline, cores Dracula)
├── modern-terminal/
│   └── setup-ghostty.sh             # Instala e configura Ghostty/zsh/Starship/...
├── DevIcons/                        # Ícones e tipos MIME para dev-icons.sh
├── Poppins/                         # Fonte Poppins (licença OFL incluída)
├── docs/
│   ├── modern-terminal.md           # Documentação do Modern Terminal
│   └── terminal-customization.html  # Guia visual + laboratório de prompt
```

---

## Arquivos que o projeto altera na sua máquina

Útil para saber o que desfazer, ou o que conferir se algo mudar de comportamento.

| Local | Alterado por | O que muda |
|---|---|---|
| `/etc/apt/sources.list.d/` e `/etc/apt/keyrings/`, `/usr/share/keyrings/` | Docker, VS Code, DBeaver | Repositórios e chaves GPG de terceiros |
| PPA `git-core/ppa` | Git | Repositório adicional |
| `~/.zshrc`, `~/.bash_aliases` | Modern Terminal | Bloco `modern-terminal` (com backup) |
| `~/.bashrc`, `~/.zshrc` | Node | Linhas de carregamento do nvm |
| `~/.config/ghostty/config.ghostty`, `~/.config/starship.toml` | Modern Terminal | Reescritos a cada execução (com backup) |
| `~/.local/share/fonts/` | Modern Terminal, default-pack | FiraCode Nerd Font, Poppins |
| `~/.local/share/icons/Yaru`, `~/.local/share/mime/packages/dev-icons.xml` | `dev-icons.sh` (manual) | Ícones de tipos de arquivo e o tipo Dockerfile |
| `~/.local/share/themes/Dracula`, `~/.config/gtk-4.0/` | Dracula Theme | Tema e CSS do GTK4 |
| `~/.docker/config.json` | Docker | Formato do `docker ps` (só se não existir) |
| `~/.nvm` | Node | Instalação do nvm e do Node |
| `~/.local/bin/claude`, `~/.local/share/claude` | Claude Code | Instalação nativa do Claude Code (só se ele não existir) |
| `~/.claude/settings.json` | Claude Code | Chave `statusLine` mesclada, o resto é mantido (com backup quando muda) |
| `~/.claude/statusline.sh` | Claude Code | Script da statusline, reescrito a cada execução (com backup se você mudou) |
| Pacote `jq` (`apt`) | Claude Code | Só se ainda não estiver instalado |
| `~/.ObsidianVault` | Obsidian | Clone do cofre de notas |
| `~/.hidden` | default-pack | Oculta a pasta `snap` |
| `gsettings` (dconf) | default-pack, Dracula, Modern Terminal, DBeaver, apps Flatpak | Tema, ícones, luz noturna, favoritos do dock, atalhos de teclado |
| Grupo `docker` | Docker | Seu usuário é adicionado |
| Shell padrão (`chsh`) | Modern Terminal | Passa a ser o `zsh` |

---

## Como adicionar um novo app

1. Crie `src/meu-app.sh` com a instalação. Prefira um repositório `apt` oficial (que se atualiza com o sistema).
   Depois, Flatpak. Use `set -e` e comandos idempotentes (no Flatpak: `flatpak info ID || flatpak install flathub ID -y`).
   Se o script chamar outro, use o caminho do próprio script (`$(dirname "${BASH_SOURCE[0]}")`) em vez de um caminho
   relativo, para ele funcionar de qualquer pasta. Se algo falhar, saia com `exit 1`. Para fixar no dock sem duplicar,
   sem abortar quando não há sessão GNOME e tratando a lista vazia:

   ```bash
   desktop_file="meu-app.desktop"
   if favorites=$(gsettings get org.gnome.shell favorite-apps 2>/dev/null); then
       if [[ "$favorites" != *"$desktop_file"* ]]; then
           if [[ "$favorites" == "[]" || "$favorites" == "@as []" ]]; then
               gsettings set org.gnome.shell favorite-apps "['$desktop_file']"
           else
               gsettings set org.gnome.shell favorite-apps "${favorites%]}, '$desktop_file']"
           fi
       fi
   fi
   ```

2. Em `main.sh`:
   - adicione o teste de instalação em `checks()` (preenchendo `array[meu_app]`; o `array` é associativo, basta usar a
     chave nova);
   - adicione a linha `False "Meu App" "${array[meu_app]}" \` em `zenity --list`;
   - adicione o bloco `if [[ "$to_install" == *"Meu App"* ]]; then bash src/meu-app.sh; fi`.

3. (Opcional) Se quiser um atalho de teclado, inclua em `default-pack.sh`.

---

## Limitações e pontos de atenção

Pontos que são do código atual, para você não ser surpreendido:

- **`default-pack` roda sempre**, sem perguntar. Isso inclui desativar atalhos do GNOME e instalar Chrome, VLC,
  qBittorrent etc. Os atalhos antigos do GNOME para captura de tela, bandeja de mensagens e mover janela entre
  áreas de trabalho são **desativados** (veja [atalhos](#atalhos-de-teclado-configurados)).
- **Cancelar o menu também aplica o `default-pack`** (é proposital). O `main.sh` chama o `default-pack` no fim sempre,
  inclusive se você fechar a janela ou clicar em Cancelar sem marcar nada. Para sair sem aplicar nada, interrompa o
  script no terminal (`Ctrl+C`) em vez de cancelar a janela.
- **Atalhos de apps que você não instalou:** o `default-pack` cria os atalhos de VS Code, DBeaver, Insomnia, Obsidian e
  Discord mesmo que você não tenha instalado esses apps. O atalho existe, mas não abre nada até o app ser instalado.
- **Obsidian clona um repositório pessoal** (`vitorguimaraes/ObsidianVault`). Se for usar em outra conta, troque a URL
  em `src/obsidian.sh`.
- **A statusline só aparece em fonte Nerd Font:** as setas do Powerline são um glifo dessa família. Sem o Modern Terminal
  (ou outra Nerd Font no terminal), elas viram quadrados.
- **Ghostty usa snap:** o `setup-ghostty.sh` instala o Ghostty com `snap install ghostty --classic`.
- **Ubuntu antigo:** o histórico do projeto registra que o tema Dracula já foi desativado por conflito com o Ubuntu 22.04.
  O instalador foi reescrito depois, mas não há confirmação de que esse conflito esteja resolvido nessa versão.

---

## Solução de problemas

**Os botões de fechar/minimizar/maximizar sumiram das janelas**
Aconteceu em versões antigas do instalador do Dracula. Atualize o repositório e rode **Dracula Theme** de novo.
Se preferir desfazer manualmente:

```bash
rm ~/.config/gtk-4.0/{gtk.css,gtk-dark.css,assets}
```

e feche e abra o app afetado.

**`docker` pede `sudo`**
Faça logout/login. A entrada no grupo `docker` só vale em novas sessões.

**O terminal continua em bash / `Ctrl+Alt+T` não abre o Ghostty**
Faça logout/login. Confira com `echo $SHELL` e `gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings`.

**O tema do GNOME Shell não aplicou**
A extensão *User Themes* precisa estar ativa. Depois de um novo login:

```bash
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
gsettings set org.gnome.shell.extensions.user-theme name 'Dracula'
```

**Quero voltar a configuração do terminal ao que era antes**
Os backups ficam ao lado dos originais, como `~/.zshrc.bak.<data-hora>`, `~/.config/starship.toml.bak.<data-hora>` etc.
Copie o backup de volta por cima do arquivo atual.

**A statusline do Claude Code não aparece ou está vazia**
Confira se `command -v jq` responde e se `~/.claude/statusline.sh` existe e é executável; se não, rode a opção **Claude Code**
de novo. Para ver a linha com dados de exemplo:
`echo '{"model":{"display_name":"Sonnet 5.5"},"context_window":{"used_percentage":42}}' | ~/.claude/statusline.sh`. Sem nenhum
dado o script não imprime nada, de propósito. Setas viradas em quadrados indicam que o terminal não está usando a FiraCode Nerd
Font. O backup do `settings.json` anterior fica ao lado, como `~/.claude/settings.json.bak.<data-hora>`.

**Um script falhou no meio**
Os instaladores são idempotentes. Corrija a causa (rede, repositório indisponível...) e rode o mesmo
instalador de novo, isoladamente: `bash src/<app>.sh`.

---

## Licenças de terceiros

- A fonte **Poppins** (`Poppins/`) é distribuída sob a SIL Open Font License; veja `Poppins/OFL.txt`.
- Os demais programas são instalados a partir das fontes oficiais, cada um com a sua licença.
