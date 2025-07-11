#!/bin/bash

set -e

# Verifica se é Fedora
if ! grep -qi "fedora" /etc/os-release; then
    echo "🚫 Este script é exclusivo para Fedora."
    exit 1
fi

# Função 1: Instalação base e ZSH
instalacao_basica() {
    echo "[0/12] Atualizando sistema..."
    sudo dnf update -y

    echo "[1/12] Instalando pacotes base..."
    sudo dnf install -y zsh git wget curl python3-pip dnf-plugins-core
    git config --global user.name "Paulo Roberto Menezes"
    git config --global user.email paulomenezes.web@gmail.com
    git config --global init.defaultBranch main

    echo "Instalando Brave Browser"
    curl -fsS https://dl.brave.com/install.sh | sh

    echo "[2/12] Habilitando repositório do Google Chrome..."
    sudo dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm

    echo "[3/12] Instalando VS Code (via repositório oficial)..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo dnf install -y code

    echo "[4/12] Instalando Oh My Zsh..."
    if [ "$SHELL" != "/bin/zsh" ]; then
        chsh -s /bin/zsh
    fi
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        echo "⚠️ Reinicie o terminal ou rode 'zsh' para aplicar o Zsh."
        zsh
    else
        echo "Oh My Zsh já está instalado."
    fi
}

# Função 2: Desenvolvimento e apps
instalacao_desenvolvimento() {
    echo "[5/12] Instalando Docker..."
    sudo dnf install -y docker
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"
    echo "⚠️ Adicionado '$USER' ao grupo docker. Reinicie a sessão para aplicar."

    echo "[6/12] Instalando SDKMAN e Java 21 Azul Zulu..."
    if [ ! -d "$HOME/.sdkman" ]; then
        curl -s "https://get.sdkman.io" | bash
    fi
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk install java 21.0.6-zulu

    echo "[7/12] Instalando NVM e Node.js LTS..."
    if [ ! -d "$HOME/.nvm" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    fi
    export NVM_DIR="$HOME/.nvm"
    source "$NVM_DIR/nvm.sh"
    nvm install --lts

    echo "[8/12] Instalando virtualenvwrapper via pip..."
    pip3 install --user virtualenvwrapper

    echo "[9/12] Configurando virtualenvwrapper no .zshrc..."
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

    echo "[10/12] Instalando Flatpak e repositório Flathub..."
    sudo dnf install -y flatpak
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    sudo dnf install -y gnome-tweaks gnome-extensions-app

    echo "[11/12] Instalando apps via Flatpak..."
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
    echo -e "\n===== Menu de Instalação Fedora ====="
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