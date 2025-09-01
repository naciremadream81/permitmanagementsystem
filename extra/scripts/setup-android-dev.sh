#!/bin/bash

# Android Development Environment Setup Script
set -e

echo "🤖 Setting up Android Development Environment..."

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on supported system
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    print_error "This script is designed for Linux systems"
    exit 1
fi

# Step 1: Install required dependencies
print_step "Installing required dependencies..."
sudo apt update
sudo apt install -y \
    wget \
    unzip \
    openjdk-21-jdk \
    libc6:i386 \
    libncurses5:i386 \
    libstdc++6:i386 \
    lib32z1 \
    libbz2-1.0:i386 \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils

print_success "Dependencies installed"

# Step 2: Create Android directory structure
print_step "Creating Android directory structure..."
ANDROID_HOME="$HOME/Android"
mkdir -p "$ANDROID_HOME"
mkdir -p "$ANDROID_HOME/Sdk"
mkdir -p "$HOME/.android"

print_success "Directory structure created"

# Step 3: Download Android Studio
print_step "Downloading Android Studio..."
ANDROID_STUDIO_VERSION="2024.2.1.12"
ANDROID_STUDIO_URL="https://redirector.gvt1.com/edgedl/android/studio/ide-zips/${ANDROID_STUDIO_VERSION}/android-studio-${ANDROID_STUDIO_VERSION}-linux.tar.gz"

cd "$HOME/Downloads" || mkdir -p "$HOME/Downloads" && cd "$HOME/Downloads"

if [ ! -f "android-studio-${ANDROID_STUDIO_VERSION}-linux.tar.gz" ]; then
    print_step "Downloading Android Studio (this may take a while)..."
    wget -O "android-studio-${ANDROID_STUDIO_VERSION}-linux.tar.gz" "$ANDROID_STUDIO_URL"
    print_success "Android Studio downloaded"
else
    print_success "Android Studio already downloaded"
fi

# Step 4: Extract Android Studio
print_step "Extracting Android Studio..."
if [ ! -d "$HOME/android-studio" ]; then
    tar -xzf "android-studio-${ANDROID_STUDIO_VERSION}-linux.tar.gz" -C "$HOME/"
    print_success "Android Studio extracted to $HOME/android-studio"
else
    print_success "Android Studio already extracted"
fi

# Step 5: Download Android SDK Command Line Tools
print_step "Downloading Android SDK Command Line Tools..."
SDK_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
cd "$ANDROID_HOME"

if [ ! -f "commandlinetools-linux-latest.zip" ]; then
    wget -O "commandlinetools-linux-latest.zip" "$SDK_TOOLS_URL"
    print_success "SDK Command Line Tools downloaded"
else
    print_success "SDK Command Line Tools already downloaded"
fi

# Step 6: Extract and setup SDK tools
print_step "Setting up SDK Command Line Tools..."
if [ ! -d "$ANDROID_HOME/cmdline-tools" ]; then
    unzip -q "commandlinetools-linux-latest.zip"
    mkdir -p "$ANDROID_HOME/cmdline-tools/latest"
    mv cmdline-tools/* "$ANDROID_HOME/cmdline-tools/latest/"
    rmdir cmdline-tools
    print_success "SDK Command Line Tools set up"
else
    print_success "SDK Command Line Tools already set up"
fi

# Step 7: Set up environment variables
print_step "Setting up environment variables..."
ENV_FILE="$HOME/.bashrc"

# Remove existing Android environment variables
sed -i '/# Android Development Environment/,/# End Android Environment/d' "$ENV_FILE"

# Add new environment variables
cat >> "$ENV_FILE" << 'EOF'

# Android Development Environment
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$HOME/android-studio/bin
# End Android Environment
EOF

# Source the environment
source "$ENV_FILE"
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$HOME/android-studio/bin"

print_success "Environment variables configured"

# Step 8: Accept SDK licenses and install essential packages
print_step "Installing essential Android SDK packages..."
cd "$ANDROID_HOME"

# Accept licenses first
yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --licenses > /dev/null 2>&1 || true

# Install essential packages
"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" \
    "platform-tools" \
    "platforms;android-34" \
    "platforms;android-33" \
    "build-tools;34.0.0" \
    "build-tools;33.0.2" \
    "emulator" \
    "system-images;android-34;google_apis;x86_64" \
    "system-images;android-33;google_apis;x86_64"

print_success "Essential SDK packages installed"

# Step 9: Create AVD (Android Virtual Device)
print_step "Creating Android Virtual Device..."
AVD_NAME="Pixel_7_API_34"

# Check if AVD already exists
if ! "$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager" list avd | grep -q "$AVD_NAME"; then
    echo "no" | "$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager" create avd \
        -n "$AVD_NAME" \
        -k "system-images;android-34;google_apis;x86_64" \
        -d "pixel_7"
    print_success "Android Virtual Device '$AVD_NAME' created"
else
    print_success "Android Virtual Device '$AVD_NAME' already exists"
fi

# Step 10: Update project configuration
print_step "Updating project configuration..."
cd "/home/archie/codebase/permitmanagementsystem"

# Update local.properties
echo "sdk.dir=$ANDROID_HOME" > local.properties
print_success "local.properties updated"

# Step 11: Create desktop launcher for Android Studio
print_step "Creating Android Studio desktop launcher..."
DESKTOP_FILE="$HOME/.local/share/applications/android-studio.desktop"
mkdir -p "$(dirname "$DESKTOP_FILE")"

cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Android Studio
Comment=The Official IDE for Android
Exec=$HOME/android-studio/bin/studio.sh
Icon=$HOME/android-studio/bin/studio.png
Categories=Development;IDE;
Terminal=false
StartupWMClass=jetbrains-studio
EOF

chmod +x "$DESKTOP_FILE"
print_success "Android Studio desktop launcher created"

# Step 12: Test the setup
print_step "Testing Android development setup..."

# Test ADB
if command -v adb &> /dev/null; then
    print_success "ADB is available"
    adb version
else
    print_warning "ADB not found in PATH, you may need to restart your terminal"
fi

# Test SDK Manager
if [ -f "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
    print_success "SDK Manager is available"
else
    print_error "SDK Manager not found"
fi

echo ""
echo "🎉 Android Development Environment Setup Complete!"
echo ""
echo "📋 What was installed:"
echo "  ✅ Android Studio IDE"
echo "  ✅ Android SDK (API 33, 34)"
echo "  ✅ Build Tools"
echo "  ✅ Platform Tools (ADB, Fastboot)"
echo "  ✅ Android Emulator"
echo "  ✅ Virtual Device (Pixel 7 API 34)"
echo ""
echo "🚀 Next Steps:"
echo "1. Restart your terminal or run: source ~/.bashrc"
echo "2. Start Android Studio: android-studio/bin/studio.sh"
echo "3. Or use the desktop launcher from your applications menu"
echo "4. Build the Android app: ./gradlew :composeApp:assembleDebug"
echo ""
echo "📱 Quick Commands:"
echo "  Start Android Studio: studio.sh"
echo "  List AVDs: avdmanager list avd"
echo "  Start emulator: emulator -avd Pixel_7_API_34"
echo "  Build debug APK: ./gradlew :composeApp:assembleDebug"
echo ""
echo "⚠️  Important: You need to restart your terminal for PATH changes to take effect!"
