#!/bin/bash

set -e

# Verifica se é Ubuntu ou Mint
if ! grep -qiE 'ubuntu|linuxmint' /etc/os-release; then
    echo "🚫 Este script é exclusivo para Ubuntu ou Linux Mint."
    exit 1
fi

echo "[0/12] Atualizando sistema..."
sudo apt update && sudo apt upgrade -y

echo "[1/12] Instalando pacotes base..."
sudo apt install -y zsh git curl wget python3-pip flatpak gnome-software-plugin-flatpak ca-certificates gnupg lsb-release apt-transport-https
git config --global user.name "Paulo Roberto Menezes"
git config --global user.email paulomenezes.web@gmail.com
git config --global init.defaultBranch main

echo "Instalando Brave Browser"
curl -fsS https://dl.brave.com/install.sh | sh

echo "[2/12] Instalando Google Chrome..."
wget -q -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y /tmp/google-chrome.deb

echo "[3/12] Instalando VS Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt update
sudo apt install -y code

echo "[4/12] Instalando Oh My Zsh..."
if [ "$SHELL" != "/usr/bin/zsh" ]; then
    chsh -s /usr/bin/zsh
fi
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh já instalado."
fi

echo "[5/12] Instalando Docker (modo Ubuntu/Mint)..."
sudo apt remove -y docker docker-engine docker.io containerd runc || true
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker "$USER"
echo "⚠️ Adicionado '$USER' ao grupo docker. Reinicie a sessão para aplicar."

echo "[6/12] Instalando SDKMAN e Java 21 Azul Zulu..."
if [ ! -d "$HOME/.sdkman" ]; then
    curl -s "https://get.sdkman.io" | bash
fi
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install java 21.0.0-zulu

echo "[7/12] Instalando NVM e Node.js LTS..."
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm install --lts

echo "[8/12] Instalando virtualenvwrapper via pip..."
pip3 install --user virtualenvwrapper

echo "[9/12] Configurando virtualenvwrapper no ~/.zshrc..."
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

echo "[10/12] Configurando Flathub..."
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
echo "Instalando extensões adicionais do gnome"
sudo apt install gnome-tweaks
sudo apt install gnome-extensions-app
sudo apt install chrome-gnome-shell

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

echo "[12/12] Instalando JetBrains Toolbox..."
TOOLBOX_TMP="/tmp/jetbrains-toolbox.tar.gz"
TOOLBOX_DIR="/opt/jetbrains-toolbox"
wget -qO "$TOOLBOX_TMP" https://data.services.jetbrains.com/products/download?code=TBA&platform=linux
sudo mkdir -p "$TOOLBOX_DIR"
sudo tar -xzf "$TOOLBOX_TMP" -C "$TOOLBOX_DIR" --strip-components=1
"$TOOLBOX_DIR/jetbrains-toolbox" &

echo "✅ Pós-instalação concluída com sucesso!"
echo "🔁 Reinicie sua sessão para aplicar ZSH, Docker e virtualenvwrapper."
echo "💡 Use o JetBrains Toolbox para instalar PyCharm e IntelliJ IDEA."
