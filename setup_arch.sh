#!/bin/bash

set -e

# Verifica se é Arch ou Manjaro
if ! grep -qiE 'arch|manjaro' /etc/os-release; then
    echo "🚫 Este script só funciona no Arch Linux ou Manjaro."
    exit 1
fi

echo "[0/12] Atualizando pacman..."
sudo pacman -Syu --noconfirm

# Verifica e instala yay se necessário
if ! command -v yay &> /dev/null; then
    echo "[1/12] yay não encontrado. Instalando yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
else
    echo "[1/12] yay já está instalado."
fi

echo "[2/12] Instalando pacotes base..."
sudo pacman -S --noconfirm git zsh docker wget curl python-pip
git config --global user.name "Paulo Roberto Menezes"
git config --global user.email paulomenezes.web@gmail.com
git config --global init.defaultBranch main

echo "Instalando Brave Browser"
curl -fsS https://dl.brave.com/install.sh | sh

echo "[3/12] Instalando Google Chrome via yay..."
yay -S --noconfirm google-chrome

echo "[4/12] Instalando Visual Studio Code via yay..."
yay -S --noconfirm visual-studio-code-bin

echo "[5/12] Instalando Oh My Zsh..."
if [ "$SHELL" != "/bin/zsh" ]; then
    chsh -s /bin/zsh
fi
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh já está instalado."
fi

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

echo "[8/12] Instalando e configurando Docker..."
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker "$USER"
echo "⚠️ Adicionado '$USER' ao grupo docker. Reinicie a sessão para aplicar."

echo "[9/12] Instalando virtualenvwrapper via pip..."
pip3 install --user virtualenvwrapper

echo "[10/12] Configurando virtualenvwrapper no ~/.zshrc..."
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

echo "[11/12] Instalando Flatpak e adicionando repositório Flathub..."
sudo pacman -S --noconfirm flatpak
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
