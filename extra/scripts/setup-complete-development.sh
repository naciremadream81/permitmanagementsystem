#!/bin/bash
set -e

echo "🛠️  Setting up complete development environment..."

# Install IntelliJ IDEA
echo "Installing IntelliJ IDEA..."
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

# Install Android Studio
echo "Installing Android Studio..."
case "$OSTYPE" in
    linux-gnu*)
        if command -v snap &> /dev/null; then
            sudo snap install android-studio --classic
        else
            echo "Please install Android Studio manually from https://developer.android.com/studio"
        fi
        ;;
    darwin*)
        if command -v brew &> /dev/null; then
            brew install --cask android-studio
        else
            echo "Please install Android Studio manually from https://developer.android.com/studio"
        fi
        ;;
    *)
        echo "Please install Android Studio manually from https://developer.android.com/studio"
        ;;
esac

# Install useful development tools
echo "Installing development tools..."
case "$OSTYPE" in
    linux-gnu*)
        if command -v apt &> /dev/null; then
            sudo apt install -y git curl wget vim nano htop tree
        fi
        ;;
    darwin*)
        if command -v brew &> /dev/null; then
            brew install git curl wget vim nano htop tree
        fi
        ;;
esac

echo "✅ Development environment setup complete!"
echo
echo "Next steps:"
echo "1. Open IntelliJ IDEA and import this project"
echo "2. Open Android Studio and import this project"
echo "3. Configure your server URL in the apps"
echo "4. Start developing!"
