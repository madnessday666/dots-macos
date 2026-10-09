#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_HOME_CONFIG_DIR="$SCRIPT_DIR/home"
BREW="/opt/homebrew/bin/brew"

#########################
# 0. Start installation #
#########################

echo "[Start] Initial setup started..."

##################################################
# 1. Install Homebrew (if not already installed) #
##################################################

if ! command -v brew &> /dev/null; then
    echo "[System] Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Для Apple Silicon
    if [[ "$(uname -m)" == "arm64" ]]; then
        # Проверяем, существует ли brew
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            BREW="/opt/homebrew/bin/brew"
            # Добавляем в .zprofile
            if ! grep -qF 'eval "$(/opt/homebrew/bin/brew shellenv)"' "$HOME/.zprofile"; then
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
                echo "[Homebrew] Added brew shellenv to .zprofile"
            fi
            # Загружаем прямо сейчас
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            echo "[ERROR] Homebrew installation failed!"
            exit 1
        fi
    fi
fi

# Проверяем, что brew доступен
if ! command -v brew &> /dev/null; then
    echo "[ERROR] Homebrew not found in PATH"
    exit 1
fi

######################
# 2. Update Homebrew #
######################

echo "[Homebrew] Updating Homebrew..."
brew update

############################
# 3. Install brew packages #
############################

TAPS=(
    certak-com/kafkio
)

PACKAGES=(
    dockutil
    duti
    eza
    fresh-editor
    git
    gradle
    mise
    node
    python
    rust
    starship
    taplo
    unar
)

CASKS=(
    bruno
    cyberduck
    datagrip
    docker
    elasticvue
    font-departure-mono-nerd-font
    font-jetbrains-mono-nerd-font
    icdiff
    intellij-idea
    kafkio
    omniwm
    spotify
    telegram
    yandextelemost
    vorssaint
    waterfox
    zed
)

echo "[Homebrew] Tapping repositories..."
"$BREW" tap "${TAPS[@]}"
"$BREW" trust "${TAPS[@]}"

echo "[Homebrew] Installing CLI packages..."
"$BREW" install "${PACKAGES[@]}"

echo "[Homebrew] Installing GUI apps..."
"$BREW" install --cask "${CASKS[@]}"

# 3.1 Remove from quarantine #
echo "[System] Removing apps from quarantine..."
sudo xattr -r -d com.apple.quarantine /Applications/Zed.app

#############################
# 4. Install other packages #
#############################

# 4.1 install zsh-shift-select plugin for zsh
echo "[git] Installing zsh-shift-select plugin..."
if [ ! -d "$HOME/zsh-plugins/zsh-shift-select" ]; then
    mkdir -p "$HOME/zsh-plugins"
    git clone https://github.com/jirutka/zsh-shift-select.git "$HOME/zsh-plugins/zsh-shift-select"
else
    echo "  Plugin already exists, skipping..."
fi

##################################
# 5. Execute additional commands #
##################################

# 5.1 mise #
echo "[mise] Downloading and configuring JDKs..."

if command -v mise &> /dev/null; then
    JDKS=(
        java@temurin-17
        java@temurin-21
        java@temurin-25
    )

    eval "$(mise activate bash)"

    for jdk in "${JDKS[@]}"; do
        echo "[mise] Installing $jdk..."
        mise install "$jdk" 2>/dev/null || echo "  [WARN] $jdk installation failed"
    done
else
    echo "[WARN] mise not installed, skipping JDK setup"
fi

# 5.2 duti #
echo "[duti] Configuring default applications..."

if command -v duti &> /dev/null; then
    if [ -d "/Applications/Zed.app" ]; then
        sudo xattr -r -d com.apple.quarantine /Applications/Zed.app 2>/dev/null || true
    fi

    EXTENSIONS=(
        public.plain-text
        public.text
        public.source-code
        net.daringfireball.markdown
        .txt
        .md
        .markdown
        .asciidoc
        .yaml
        .yml
        .toml
        .ini
        .conf
        .cfg
        .xml
        .env
        .js
        .ts
        .jsx
        .tsx
        .json
        .jsonc
        .css
        .scss
        .py
        .rb
        .go
        .rs
        .c
        .cpp
        .h
        .hpp
        .cs
        .php
        .sh
        .bash
        .zsh
        .log
        .sql
        .csv
        .tsv
    )

    for ext in "${EXTENSIONS[@]}"; do
        echo "  [duti] Associating $ext with Zed"
        duti -s dev.zed.Zed "$ext" all 2>/dev/null || echo "  [WARN] Failed to associate $ext"
    done
else
    echo "[WARN] duti not installed, skipping file associations"
fi

# 5.3 dockutil #
echo "[dockutil] Managing app positions..."

if command -v dockutil &> /dev/null; then
    APPS=(
        '/Applications/Waterfox.app'
        '/Applications/IntelliJ IDEA.app'
        '/Applications/Zed.app'
        '/Applications/DataGrip.app'
        '/Applications/Bruno.app'
        '/Applications/Docker.app/Contents/MacOS/Docker Desktop.app'
        '/Applications/Elasticvue.app'
        '/Applications/KafkIO.app'
        '/Applications/Cyberduck.app'
        '/System/Applications/Mail.app'
        '/System/Applications/Calendar.app'
        '/Applications/Spotify.app'
    )

    APPS_ALWAYS_AT_END=(
        '/Applications/Telegram.app'
        '/Applications/Yandex.Telemost.app'
    )

    # Очищаем Dock
    dockutil --remove all --no-restart 2>/dev/null || true

    CURRENT_DOCK_POS=1
    for app_path in "${APPS[@]}"; do
        if [ -d "$app_path" ] || [ -d "${app_path%.app}.app" ]; then
            echo "[dockutil] Adding $(basename "$app_path")..."
            dockutil --add "$app_path" --position "$CURRENT_DOCK_POS" --no-restart 2>/dev/null || true
            CURRENT_DOCK_POS=$((CURRENT_DOCK_POS + 1))
        else
            echo "[dockutil] Warning: $app_path not found. Skipping..."
        fi
    done

    for app_path in "${APPS_ALWAYS_AT_END[@]}"; do
        if [ -d "$app_path" ]; then
            echo "[dockutil] Adding $(basename "$app_path") to end..."
            dockutil --add "$app_path" --position end --no-restart 2>/dev/null || true
        else
            echo "[dockutil] Warning: $app_path not found. Skipping..."
        fi
    done
else
    echo "[WARN] dockutil not installed, skipping dock setup"
fi

################################################
# 6. Initialize default configs and copy files #
################################################

echo "[System] Initializing default configs and copying files..."

# 6.1 create dirs
mkdir -p "$HOME/.config"
mkdir -p "$HOME/Screenshots"

# 6.2 copy common files #
if [ -d "$SCRIPT_HOME_CONFIG_DIR" ]; then
    echo "[System] Copying common files..."
    cp -rf "$SCRIPT_HOME_CONFIG_DIR/." "$HOME"
fi

###########################################
# 998. Configure macOS System Preferences #
###########################################

echo "[System] Configuring macOS settings..."

echo "[System] Enabling dock autohide..."
defaults write com.apple.dock autohide -bool true

############################
# 999. Restart system apps #
############################

killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true

##########################
# 1000. End installation #
##########################

echo "[Done] Initial setup completed successfully!"
echo "[System] Please RESTART your Terminal application to apply all changes."
