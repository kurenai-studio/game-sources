#!/usr/bin/env bash
# setup.sh — Install LÖVE 2D on Linux (Fedora/RHEL, Debian/Ubuntu, Arch) or macOS.
# Usage: ./scripts/setup.sh
set -euo pipefail

LOVE_VERSION="11.5"

echo "==> Breakout setup: installing LÖVE ${LOVE_VERSION}"

# ---- macOS ---------------------------------------------------------------
if [[ "$(uname)" == "Darwin" ]]; then
    if command -v brew >/dev/null 2>&1; then
        echo "==> Homebrew found: brew install --cask love"
        brew install --cask love
    else
        tmp="$(mktemp -d)"
        echo "==> Downloading LÖVE.app..."
        curl -fL -o "$tmp/love.zip" \
            "https://github.com/love2d/love/releases/download/${LOVE_VERSION}/love-${LOVE_VERSION}-macos.zip"
        unzip -q "$tmp/love.zip" -d "$tmp"
        mkdir -p "$HOME/Applications"
        cp -R "$tmp/love.app" "$HOME/Applications/"
        echo "==> Installed: $HOME/Applications/love.app"
        echo "    Open it once (it adds itself to PATH). Or run: scripts/run.sh"
    fi
    exit 0
fi

# ---- Linux ---------------------------------------------------------------
if [[ "$(uname)" == "Linux" ]]; then
    if command -v dnf >/dev/null 2>&1; then
        echo "==> Fedora/RHEL: sudo dnf install -y love"
        sudo dnf install -y love
    elif command -v apt-get >/dev/null 2>&1; then
        echo "==> Debian/Ubuntu: sudo apt-get install -y love"
        sudo apt-get update && sudo apt-get install -y love
    elif command -v pacman >/dev/null 2>&1; then
        echo "==> Arch: sudo pacman -S --noconfirm love"
        sudo pacman -S --noconfirm love
    else
        echo "==> No package manager detected; downloading the AppImage..."
        tmp="$(mktemp -d)"
        curl -fL -o "$tmp/love.AppImage" \
            "https://github.com/love2d/love/releases/download/${LOVE_VERSION}/love-${LOVE_VERSION}-x86_64.AppImage"
        chmod +x "$tmp/love.AppImage"
        mkdir -p "$HOME/.local/bin"
        cp "$tmp/love.AppImage" "$HOME/.local/bin/love"
        echo "==> Installed AppImage to $HOME/.local/bin/love"
    fi
fi

# ---- Verify --------------------------------------------------------------
if command -v love >/dev/null 2>&1; then
    echo "==> LÖVE ready: $(love --version)"
else
    echo "==> 'love' is not on PATH."
    echo "    - Fedora/RHEL: the binary is /usr/bin/love"
    echo "    - AppImage    : export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo "    - macOS       : open the app once, or run: scripts/run.sh"
fi
