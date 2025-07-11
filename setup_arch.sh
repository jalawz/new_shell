#!/bin/bash

set -e

# Verifica se é Arch ou Manjaro
if ! grep -qiE "arch|manjaro" /etc/os-release; then
    echo "🚫 Este script é exclusivo para Arch Linux ou Manjaro."
    exit 1
fi

# Função 1: Instalação base e ZSH
instalacao_basica() {
    echo "[0/12] Atualizando sistema..."
    sudo pacman -Syu --noconfirm

    echo "[1/12] Instalando pacotes base..."
    sudo pacman -S --noconfirm git wget curl python-pip base-devel

    git config --global user.name "Paulo Roberto Menezes"
    git config --global user.email paulomenezes.web@gmail.com
    git config --global init.defaultBranch main

    # Detecta ambiente gráfico
    AMBIENTE=$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]')

    if [[ "$AMBIENTE" == *"kde"* ]]; then
        echo "🖥️ Ambiente KDE detectado. Instalando ZSH com Powerlevel10k (sem Oh My Zsh)..."
        sudo pacman -S --noconfirm zsh zsh-completions

        # Troca shell padrão para zsh
        if [ "$SHELL" != "/bin/zsh" ]; then
            chsh -s /bin/zsh
        fi

        # Instala Powerlevel10k
        if [ ! -d "$HOME/.zsh/powerlevel10k" ]; then
            git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.zsh/powerlevel10k
        fi

        # Cria .zshrc simples com Powerlevel10k
        if [ ! -f "$HOME/.zshrc" ]; then
            cat << 'EOF' > ~/.zshrc
# Tema Powerlevel10k
source ~/.zsh/powerlevel10k/powerlevel10k.zsh-theme

# Histórico
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# Atalhos
alias ll='ls -la'
alias gs='git status'

# Inicialização
autoload -Uz compinit promptinit
compinit
promptinit

# Usa o tema
prompt powerlevel10k
EOF
        fi

        echo "✅ ZSH com Powerlevel10k instalado e configurado."
        echo "ℹ️ Rode 'p10k configure' para personalizar o tema depois, se desejar."
    else
        echo "🖥️ Ambiente GNOME detectado. Pulando instalação de ZSH/Powerlevel10k."
    fi

    echo "[2/12] Instalando Brave Browser (via AUR)..."
    if ! command -v yay >/dev/null 2>&1; then
        echo "Instalando yay (AUR helper)..."
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
    fi
    yay -S --noconfirm brave-bin

    echo "[3/12] Instalando Google Chrome (via AUR)..."
    yay -S --noconfirm google-chrome

    echo "[4/12] Instalando VS Code (via repositório oficial)..."
    sudo pacman -S --noconfirm code
}

# Função 2: Desenvolvimento e apps
instalacao_desenvolvimento() {
    echo "[6/12] Instalando Docker..."
    sudo pacman -S --noconfirm docker
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"
    echo "⚠️ Adicionado '$USER' ao grupo docker. Reinicie a sessão para aplicar."

    echo "[7/12] Instalando SDKMAN e Java 21 Azul Zulu..."
    if [ ! -d "$HOME/.sdkman" ]; then
        curl -s "https://get.sdkman.io" | bash
    fi
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk install java 21.0.6-zulu

    echo "[8/12] Instalando NVM e Node.js LTS..."
    if [ ! -d "$HOME/.nvm" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    fi
    export NVM_DIR="$HOME/.nvm"
    source "$NVM_DIR/nvm.sh"
    nvm install --lts

    echo "[9/12] Instalando virtualenvwrapper via pip..."
    yay -S --noconfirm python-virtualenvwrapper

    echo "[10/12] Configurando virtualenvwrapper no .zshrc..."
    VENV_CONFIG="
# Virtualenvwrapper config
export WORKON_HOME=\$HOME/.virtualenvs
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
source \$HOME/.local/bin/virtualenvwrapper.sh
"
    if ! grep -q "virtualenvwrapper.sh" ~/.zshrc; then
        echo "$VENV_CONFIG" >> ~/.zshrc
        echo "✅ virtualenvwrapper configurado no ~/.zshrc"
    else
        echo "ℹ️ virtualenvwrapper já configurado no ~/.zshrc"
    fi

    echo "[11/12] Instalando Flatpak e apps..."
    sudo pacman -S --noconfirm flatpak gnome-tweaks gnome-extensions-app
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    echo "[12/12] Instalando apps via Flatpak..."
    flatpak install -y flathub \
      io.github.getnf.embellish \
      com.rtosta.zapzap \
      com.obsproject.Studio \
      org.duckstation.DuckStation \
      org.ppsspp.PPSSPP \
      com.heroicgameslauncher.hgl \
      net.lutris.Lutris \
      net.pcsx2.PCSX2 \
      com.discordapp.Discord \
      org.telegram.desktop \
      com.getpostman.Postman \
      io.dbeaver.DBeaverCommunity \
      org.gnome.meld \
      io.httpie.Httpie

    echo "✅ Configurações de desenvolvimento e apps concluídas!"
    echo "🔁 Reinicie sua sessão para aplicar Docker, virtualenvwrapper, e SDKs."
}

# Menu interativo
while true; do
    echo -e "\n===== Menu de Instalação Arch/Manjaro ====="
    echo "1) Instalação Básica (ZSH, Brave, Chrome, VSCode, Oh My Zsh)"
    echo "2) Instalação para Desenvolvimento (Docker, SDKMAN, NVM, Flatpak, etc)"
    echo "0) Sair"
    read -rp "Escolha uma opção: " opcao

    case $opcao in
        1) instalacao_basica ;;
        2) instalacao_desenvolvimento ;;
        0) echo "Saindo..."; break ;;
        *) echo "Opção inválida. Tente novamente." ;;
    esac
done
