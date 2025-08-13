#!/bin/bash

# Install glow for terminal-based markdown preview
# For Ubuntu/Debian:
if command -v apt &> /dev/null; then
    echo "Installing glow using apt..."
    sudo apt update
    sudo apt install -y glow
# For Fedora:
elif command -v dnf &> /dev/null; then
    echo "Installing glow using dnf..."
    sudo dnf install -y glow
# For Arch Linux:
elif command -v pacman &> /dev/null; then
    echo "Installing glow using pacman..."
    sudo pacman -S glow
# For macOS with Homebrew:
elif command -v brew &> /dev/null; then
    echo "Installing glow using Homebrew..."
    brew install glow
else
    echo "Please install glow manually from: https://github.com/charmbracelet/glow"
fi

echo "Installation complete! Please restart Neovim to use the markdown features."