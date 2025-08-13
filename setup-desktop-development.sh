#!/bin/bash
# Desktop Development Environment Setup

echo "Setting up desktop development environment..."

# Install IntelliJ IDEA Community Edition
case "$OSTYPE" in
    linux-gnu*)
        if command -v snap &> /dev/null; then
            sudo snap install intellij-idea-community --classic
        else
            echo "Please install IntelliJ IDEA manually from https://www.jetbrains.com/idea/download/"
        fi
        ;;
    darwin*)
        if command -v brew &> /dev/null; then
            brew install --cask intellij-idea-ce
        else
            echo "Please install IntelliJ IDEA manually from https://www.jetbrains.com/idea/download/"
        fi
        ;;
    *)
        echo "Please install IntelliJ IDEA manually from https://www.jetbrains.com/idea/download/"
        ;;
esac

echo "Development environment setup complete!"
echo "To develop the desktop app:"
echo "1. Open IntelliJ IDEA"
echo "2. Open this project"
echo "3. Run the 'composeApp' configuration"
