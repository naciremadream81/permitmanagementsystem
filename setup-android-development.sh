#!/bin/bash
# Android Development Environment Setup

echo "Setting up Android development environment..."

# Install Android Studio
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

echo "Development environment setup complete!"
echo "Next steps:"
echo "1. Run Android Studio"
echo "2. Complete the setup wizard"
echo "3. Install Android SDK"
echo "4. Open this project in Android Studio"
echo "5. Run the 'composeApp' configuration"
