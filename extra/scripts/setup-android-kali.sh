#!/bin/bash

# Android Development Environment Setup Script for Kali Linux
set -e

echo "🤖 Setting up Android Development Environment for Kali Linux..."

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

# Step 1: Install required dependencies (Kali-specific)
print_step "Installing required dependencies for Kali Linux..."
sudo apt update
sudo apt install -y \
    wget \
    unzip \
    openjdk-21-jdk \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    android-tools-adb \
    android-tools-fastboot

print_success "Dependencies installed"

# Step 2: Enable multiarch for 32-bit support (needed for Android emulator)
print_step "Enabling 32-bit architecture support..."
sudo dpkg --add-architecture i386
sudo apt update

# Try to install 32-bit libraries (some may not be available in Kali)
print_step "Installing 32-bit libraries (some may be skipped)..."
sudo apt install -y \
    lib32z1 \
    lib32stdc++6 \
    lib32gcc-s1 \
    lib32ncurses6 \
    libc6-i386 || print_warning "Some 32-bit libraries not available, emulator may have issues"

print_success "32-bit support configured"

# Step 3: Create Android directory structure
print_step "Creating Android directory structure..."
ANDROID_HOME="$HOME/Android"
mkdir -p "$ANDROID_HOME"
mkdir -p "$ANDROID_HOME/Sdk"
mkdir -p "$HOME/.android"

print_success "Directory structure created"

# Step 4: Download Android Studio
print_step "Downloading Android Studio..."
ANDROID_STUDIO_VERSION="2024.2.1.12"
ANDROID_STUDIO_URL="https://redirector.gvt1.com/edgedl/android/studio/ide-zips/${ANDROID_STUDIO_VERSION}/android-studio-${ANDROID_STUDIO_VERSION}-linux.tar.gz"

mkdir -p "$HOME/Downloads"
cd "$HOME/Downloads"

if [ ! -f "android-studio-${ANDROID_STUDIO_VERSION}-linux.tar.gz" ]; then
    print_step "Downloading Android Studio (this may take a while)..."
    wget -O "android-studio-${ANDROID_STUDIO_VERSION}-linux.tar.gz" "$ANDROID_STUDIO_URL" || {
        print_error "Failed to download Android Studio"
        print_step "Trying alternative download method..."
        curl -L -o "android-studio-${ANDROID_STUDIO_VERSION}-linux.tar.gz" "$ANDROID_STUDIO_URL"
    }
    print_success "Android Studio downloaded"
else
    print_success "Android Studio already downloaded"
fi

# Step 5: Extract Android Studio
print_step "Extracting Android Studio..."
if [ ! -d "$HOME/android-studio" ]; then
    tar -xzf "android-studio-${ANDROID_STUDIO_VERSION}-linux.tar.gz" -C "$HOME/"
    print_success "Android Studio extracted to $HOME/android-studio"
else
    print_success "Android Studio already extracted"
fi

# Step 6: Download Android SDK Command Line Tools
print_step "Downloading Android SDK Command Line Tools..."
SDK_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
cd "$ANDROID_HOME"

if [ ! -f "commandlinetools-linux-latest.zip" ]; then
    wget -O "commandlinetools-linux-latest.zip" "$SDK_TOOLS_URL" || {
        print_error "Failed to download SDK tools with wget"
        print_step "Trying with curl..."
        curl -L -o "commandlinetools-linux-latest.zip" "$SDK_TOOLS_URL"
    }
    print_success "SDK Command Line Tools downloaded"
else
    print_success "SDK Command Line Tools already downloaded"
fi

# Step 7: Extract and setup SDK tools
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

# Step 8: Set up environment variables
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
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
# End Android Environment
EOF

# Source the environment
source "$ENV_FILE"
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$HOME/android-studio/bin"
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"

print_success "Environment variables configured"

# Step 9: Accept SDK licenses and install essential packages
print_step "Installing essential Android SDK packages..."
cd "$ANDROID_HOME"

# Make sure the sdkmanager is executable
chmod +x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"

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

# Step 10: Create AVD (Android Virtual Device)
print_step "Creating Android Virtual Device..."
AVD_NAME="Pixel_7_API_34"

# Check if AVD already exists
if ! "$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager" list avd | grep -q "$AVD_NAME"; then
    echo "no" | "$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager" create avd \
        -n "$AVD_NAME" \
        -k "system-images;android-34;google_apis;x86_64" \
        -d "pixel_7" || {
        print_warning "Failed to create AVD with pixel_7 device, trying with default device"
        echo "no" | "$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager" create avd \
            -n "$AVD_NAME" \
            -k "system-images;android-34;google_apis;x86_64"
    }
    print_success "Android Virtual Device '$AVD_NAME' created"
else
    print_success "Android Virtual Device '$AVD_NAME' already exists"
fi

# Step 11: Update project configuration
print_step "Updating project configuration..."
cd "/home/archie/codebase/permitmanagementsystem"

# Update local.properties
echo "sdk.dir=$ANDROID_HOME" > local.properties
print_success "local.properties updated"

# Step 12: Create desktop launcher for Android Studio
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

# Step 13: Create quick start scripts
print_step "Creating quick start scripts..."

# Android Studio launcher
cat > "$HOME/start-android-studio.sh" << 'EOF'
#!/bin/bash
export ANDROID_HOME=$HOME/Android/Sdk
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
$HOME/android-studio/bin/studio.sh
EOF
chmod +x "$HOME/start-android-studio.sh"

# Emulator launcher
cat > "$HOME/start-android-emulator.sh" << 'EOF'
#!/bin/bash
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
cd $ANDROID_HOME
emulator -avd Pixel_7_API_34
EOF
chmod +x "$HOME/start-android-emulator.sh"

print_success "Quick start scripts created"

# Step 14: Test the setup
print_step "Testing Android development setup..."

# Test ADB
if command -v adb &> /dev/null; then
    print_success "ADB is available"
    adb version | head -1
else
    print_warning "ADB not found in PATH, you may need to restart your terminal"
fi

# Test SDK Manager
if [ -f "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
    print_success "SDK Manager is available"
    "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --version
else
    print_error "SDK Manager not found"
fi

# Test Java
if command -v java &> /dev/null; then
    print_success "Java is available"
    java -version 2>&1 | head -1
else
    print_error "Java not found"
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
echo "  ✅ Quick start scripts"
echo ""
echo "🚀 Next Steps:"
echo "1. Restart your terminal: source ~/.bashrc"
echo "2. Start Android Studio: ~/start-android-studio.sh"
echo "3. Start Android Emulator: ~/start-android-emulator.sh"
echo "4. Build the Android app: ./gradlew :composeApp:assembleDebug"
echo ""
echo "📱 Quick Commands:"
echo "  Start Android Studio: ~/start-android-studio.sh"
echo "  Start Emulator: ~/start-android-emulator.sh"
echo "  List AVDs: \$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager list avd"
echo "  Build debug APK: ./gradlew :composeApp:assembleDebug"
echo "  Install APK: adb install composeApp/build/outputs/apk/debug/composeApp-debug.apk"
echo ""
echo "⚠️  Important Notes:"
echo "  - Restart your terminal for PATH changes to take effect"
echo "  - The emulator may be slow without hardware acceleration"
echo "  - Use 'adb devices' to check connected devices/emulators"
