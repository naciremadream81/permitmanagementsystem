#!/bin/bash

# Setup minimal Android SDK for development without full Android SDK
# This creates a minimal directory structure to satisfy Gradle

set -e

echo "🔧 Setting up minimal Android SDK for development..."

# Create minimal Android SDK structure
ANDROID_SDK_PATH="$HOME/Android/Sdk"
mkdir -p "$ANDROID_SDK_PATH"

# Create minimal directory structure
mkdir -p "$ANDROID_SDK_PATH/platforms"
mkdir -p "$ANDROID_SDK_PATH/build-tools"
mkdir -p "$ANDROID_SDK_PATH/tools"

# Create a minimal platform directory (API 34)
mkdir -p "$ANDROID_SDK_PATH/platforms/android-34"
touch "$ANDROID_SDK_PATH/platforms/android-34/android.jar"

# Create minimal build-tools directory
mkdir -p "$ANDROID_SDK_PATH/build-tools/34.0.0"
touch "$ANDROID_SDK_PATH/build-tools/34.0.0/aapt"

# Update local.properties
echo "sdk.dir=$ANDROID_SDK_PATH" > local.properties

echo "✅ Minimal Android SDK setup completed!"
echo "📁 SDK path: $ANDROID_SDK_PATH"
echo ""
echo "⚠️  Note: This is a minimal setup for development only."
echo "   For actual Android development, install the full Android SDK."
echo ""
echo "🚀 You can now run:"
echo "  ./gradlew build"
echo "  ./gradlew :server:run"
