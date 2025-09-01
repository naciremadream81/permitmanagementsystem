#!/bin/bash
set -e

# Permit Management System - Android App Deployment Script
# This script builds and packages the Android application for distribution

echo "📱 Permit Management System - Android App Deployment"
echo "===================================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        print_status "Detected OS: Linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        print_status "Detected OS: macOS"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS="windows"
        print_status "Detected OS: Windows"
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
}

# Check Java installation
check_java() {
    print_header "Checking Java Installation"
    
    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | head -n1 | cut -d'"' -f2 | cut -d'.' -f1)
        if [ "$JAVA_VERSION" -ge 17 ]; then
            print_status "Java $JAVA_VERSION found - OK"
        else
            print_error "Java 17 or higher required. Found Java $JAVA_VERSION"
            install_java
        fi
    else
        print_error "Java not found"
        install_java
    fi
}

# Install Java
install_java() {
    print_header "Installing Java 17"
    
    case $OS in
        "linux")
            if command -v apt &> /dev/null; then
                sudo apt update
                sudo apt install -y openjdk-17-jdk
            elif command -v yum &> /dev/null; then
                sudo yum install -y java-17-openjdk-devel
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y java-17-openjdk-devel
            else
                print_error "Unable to install Java automatically. Please install Java 17 manually."
                exit 1
            fi
            ;;
        "macos")
            if command -v brew &> /dev/null; then
                brew install openjdk@17
                echo 'export PATH="/usr/local/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
                export PATH="/usr/local/opt/openjdk@17/bin:$PATH"
            else
                print_error "Homebrew not found. Please install Java 17 manually from https://adoptium.net/"
                exit 1
            fi
            ;;
        "windows")
            print_error "Please install Java 17 manually from https://adoptium.net/"
            exit 1
            ;;
    esac
    
    print_status "Java 17 installed successfully"
}

# Check Android SDK
check_android_sdk() {
    print_header "Checking Android SDK"
    
    # Check for Android SDK
    if [ -n "$ANDROID_HOME" ] && [ -d "$ANDROID_HOME" ]; then
        print_status "Android SDK found at: $ANDROID_HOME"
        return 0
    fi
    
    # Common SDK locations
    COMMON_SDK_PATHS=(
        "$HOME/Android/Sdk"
        "$HOME/Library/Android/sdk"
        "/opt/android-sdk"
        "/usr/local/android-sdk"
    )
    
    for path in "${COMMON_SDK_PATHS[@]}"; do
        if [ -d "$path" ]; then
            export ANDROID_HOME="$path"
            print_status "Android SDK found at: $ANDROID_HOME"
            return 0
        fi
    done
    
    print_error "Android SDK not found"
    install_android_sdk
}

# Install Android SDK
install_android_sdk() {
    print_header "Installing Android SDK"
    
    case $OS in
        "linux")
            if command -v snap &> /dev/null; then
                print_status "Installing Android Studio via Snap..."
                sudo snap install android-studio --classic
                print_status "Android Studio installed. Please run it once to set up the SDK."
            else
                print_error "Please install Android Studio manually from https://developer.android.com/studio"
                exit 1
            fi
            ;;
        "macos")
            if command -v brew &> /dev/null; then
                print_status "Installing Android Studio via Homebrew..."
                brew install --cask android-studio
                print_status "Android Studio installed. Please run it once to set up the SDK."
            else
                print_error "Please install Android Studio manually from https://developer.android.com/studio"
                exit 1
            fi
            ;;
        "windows")
            print_error "Please install Android Studio manually from https://developer.android.com/studio"
            exit 1
            ;;
    esac
    
    print_warning "After installing Android Studio:"
    print_warning "1. Run Android Studio"
    print_warning "2. Complete the setup wizard"
    print_warning "3. Install Android SDK"
    print_warning "4. Set ANDROID_HOME environment variable"
    print_warning "5. Re-run this script"
    exit 1
}

# Configure Android SDK path
configure_android_sdk() {
    print_header "Configuring Android SDK"
    
    # Create local.properties if it doesn't exist
    if [ ! -f local.properties ]; then
        touch local.properties
    fi
    
    # Remove existing sdk.dir if present
    grep -v "sdk.dir" local.properties > local.properties.tmp || true
    mv local.properties.tmp local.properties
    
    # Add SDK path
    if [ -n "$ANDROID_HOME" ]; then
        echo "sdk.dir=$ANDROID_HOME" >> local.properties
        print_status "Android SDK configured: $ANDROID_HOME"
    else
        print_error "ANDROID_HOME not set"
        exit 1
    fi
}

# Generate signing key
generate_signing_key() {
    print_header "Configuring App Signing"
    
    KEYSTORE_FILE="permit-management.keystore"
    
    if [ -f "$KEYSTORE_FILE" ]; then
        print_status "Signing keystore already exists: $KEYSTORE_FILE"
        return 0
    fi
    
    echo -n "Generate new signing key for release builds? (y/n): "
    read GENERATE_KEY
    
    if [[ $GENERATE_KEY =~ ^[Yy]$ ]]; then
        print_status "Generating signing keystore..."
        
        # Generate keystore
        keytool -genkey -v -keystore "$KEYSTORE_FILE" \
            -alias permit-key \
            -keyalg RSA \
            -keysize 2048 \
            -validity 10000 \
            -dname "CN=Permit Management System, OU=Development, O=Organization, L=City, S=State, C=US" \
            -storepass permitmanagement123 \
            -keypass permitmanagement123
        
        print_status "Signing keystore generated: $KEYSTORE_FILE"
        print_warning "Store password: permitmanagement123"
        print_warning "Key password: permitmanagement123"
        print_warning "Change these passwords for production use!"
    else
        print_warning "Skipping signing key generation. Release builds will not be signed."
    fi
}

# Configure Gradle for Android
configure_gradle() {
    print_header "Configuring Gradle"
    
    # Find Java home
    if command -v java &> /dev/null; then
        JAVA_HOME_PATH=$(java -XshowSettings:properties -version 2>&1 | grep 'java.home' | cut -d'=' -f2 | tr -d ' ')
        
        # Set Java home in gradle.properties
        if [ ! -f gradle.properties ]; then
            touch gradle.properties
        fi
        
        # Remove existing java.home if present
        grep -v "org.gradle.java.home" gradle.properties > gradle.properties.tmp || true
        mv gradle.properties.tmp gradle.properties
        
        # Add Java home
        echo "org.gradle.java.home=$JAVA_HOME_PATH" >> gradle.properties
        
        print_status "Gradle configured with Java home: $JAVA_HOME_PATH"
    else
        print_error "Java not found after installation"
        exit 1
    fi
    
    # Add Android-specific Gradle properties
    cat >> gradle.properties << EOF

# Android-specific properties
android.useAndroidX=true
android.enableJetifier=true
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
org.gradle.parallel=true
org.gradle.caching=true
EOF
    
    print_status "Android Gradle properties configured"
}

# Build debug APK
build_debug_apk() {
    print_header "Building Debug APK"
    
    print_status "Cleaning previous builds..."
    ./gradlew clean
    
    print_status "Building debug APK..."
    ./gradlew :composeApp:assembleDebug
    
    if [ $? -eq 0 ]; then
        print_status "Debug APK built successfully"
        DEBUG_APK="composeApp/build/outputs/apk/debug/composeApp-debug.apk"
        if [ -f "$DEBUG_APK" ]; then
            print_status "Debug APK location: $DEBUG_APK"
        fi
    else
        print_error "Failed to build debug APK"
        exit 1
    fi
}

# Build release APK
build_release_apk() {
    print_header "Building Release APK"
    
    if [ ! -f "permit-management.keystore" ]; then
        print_warning "No signing keystore found. Skipping release build."
        return 0
    fi
    
    print_status "Building release APK..."
    ./gradlew :composeApp:assembleRelease
    
    if [ $? -eq 0 ]; then
        print_status "Release APK built successfully"
        RELEASE_APK="composeApp/build/outputs/apk/release/composeApp-release.apk"
        if [ -f "$RELEASE_APK" ]; then
            print_status "Release APK location: $RELEASE_APK"
        fi
    else
        print_warning "Failed to build release APK (this is normal without proper signing configuration)"
    fi
}

# Build App Bundle for Play Store
build_app_bundle() {
    print_header "Building App Bundle for Play Store"
    
    if [ ! -f "permit-management.keystore" ]; then
        print_warning "No signing keystore found. Skipping App Bundle build."
        return 0
    fi
    
    print_status "Building App Bundle..."
    ./gradlew :composeApp:bundleRelease
    
    if [ $? -eq 0 ]; then
        print_status "App Bundle built successfully"
        APP_BUNDLE="composeApp/build/outputs/bundle/release/composeApp-release.aab"
        if [ -f "$APP_BUNDLE" ]; then
            print_status "App Bundle location: $APP_BUNDLE"
        fi
    else
        print_warning "Failed to build App Bundle"
    fi
}

# Package distribution
package_distribution() {
    print_header "Packaging Distribution"
    
    # Create distribution directory
    DIST_DIR="dist/android"
    mkdir -p "$DIST_DIR"
    
    # Copy APK files
    if [ -f "composeApp/build/outputs/apk/debug/composeApp-debug.apk" ]; then
        cp "composeApp/build/outputs/apk/debug/composeApp-debug.apk" "$DIST_DIR/"
        print_status "Debug APK copied to distribution"
    fi
    
    if [ -f "composeApp/build/outputs/apk/release/composeApp-release.apk" ]; then
        cp "composeApp/build/outputs/apk/release/composeApp-release.apk" "$DIST_DIR/"
        print_status "Release APK copied to distribution"
    fi
    
    if [ -f "composeApp/build/outputs/bundle/release/composeApp-release.aab" ]; then
        cp "composeApp/build/outputs/bundle/release/composeApp-release.aab" "$DIST_DIR/"
        print_status "App Bundle copied to distribution"
    fi
    
    # Create installation instructions
    cat > "$DIST_DIR/INSTALL_INSTRUCTIONS.txt" << EOF
Permit Management System - Android App Installation
==================================================

Files in this package:
- composeApp-debug.apk: Debug version for testing
- composeApp-release.apk: Release version for production
- composeApp-release.aab: App Bundle for Google Play Store

Installation Methods:
--------------------

Method 1: Direct APK Installation
1. Enable "Unknown Sources" in Android Settings:
   Settings > Security > Unknown Sources (or Install unknown apps)
2. Transfer the APK file to your Android device
3. Tap the APK file to install
4. Follow the installation prompts

Method 2: ADB Installation (Developer)
1. Enable Developer Options and USB Debugging
2. Connect device to computer
3. Run: adb install composeApp-debug.apk

Method 3: Google Play Store (App Bundle)
1. Upload composeApp-release.aab to Google Play Console
2. Follow Google Play Store publishing guidelines
3. Users can install from Play Store once published

System Requirements:
-------------------
- Android 7.0 (API level 24) or higher
- 100MB free storage space
- Internet connection for server communication

Configuration:
--------------
The app will connect to your Permit Management System server.
Default server: http://localhost:8081

To change the server URL:
1. Open the app
2. Go to Settings
3. Enter your server URL (e.g., https://your-server.com)

Troubleshooting:
---------------
- If installation fails, ensure "Unknown Sources" is enabled
- If app crashes, check server connectivity
- For development issues, check Android Studio logs

Support:
--------
For support and documentation, visit:
https://github.com/yourusername/permitmanagementsystem
EOF
    
    # Create QR code for easy installation (if qrencode is available)
    if command -v qrencode &> /dev/null; then
        print_status "Generating QR codes for easy installation..."
        
        # Create simple HTTP server script for APK distribution
        cat > "$DIST_DIR/serve-apk.py" << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import os

PORT = 8000
os.chdir(os.path.dirname(os.path.abspath(__file__)))

Handler = http.server.SimpleHTTPRequestHandler
with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Serving APK files at http://localhost:{PORT}")
    print("Access from your Android device to download APK")
    httpd.serve_forever()
EOF
        chmod +x "$DIST_DIR/serve-apk.py"
        
        # Generate QR code for local server
        echo "http://$(hostname -I | awk '{print $1}'):8000/composeApp-debug.apk" | qrencode -t UTF8 > "$DIST_DIR/qr-code.txt"
        print_status "QR code generated for easy mobile installation"
    fi
    
    print_status "Distribution package created in $DIST_DIR"
}

# Create development setup script
create_dev_setup() {
    print_header "Creating Development Setup"
    
    cat > setup-android-development.sh << 'EOF'
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
EOF
    
    chmod +x setup-android-development.sh
    print_status "Development setup script created"
}

# Test APK installation
test_apk() {
    print_header "Testing APK"
    
    if command -v adb &> /dev/null; then
        # Check if device is connected
        DEVICES=$(adb devices | grep -v "List of devices" | grep "device$" | wc -l)
        
        if [ "$DEVICES" -gt 0 ]; then
            echo -n "Install debug APK on connected device? (y/n): "
            read INSTALL_APK
            
            if [[ $INSTALL_APK =~ ^[Yy]$ ]]; then
                print_status "Installing debug APK on device..."
                adb install -r composeApp/build/outputs/apk/debug/composeApp-debug.apk
                
                if [ $? -eq 0 ]; then
                    print_status "APK installed successfully on device"
                else
                    print_warning "APK installation failed"
                fi
            fi
        else
            print_warning "No Android devices connected via ADB"
        fi
    else
        print_warning "ADB not found. Cannot test APK installation."
    fi
}

# Display final information
display_final_info() {
    print_header "Android App Deployment Complete!"
    
    echo -e "${GREEN}🎉 Android application built successfully!${NC}"
    echo
    echo "Distribution Files:"
    echo "  📁 dist/android/ - Complete distribution package"
    echo "  📱 composeApp-debug.apk - Debug version for testing"
    
    if [ -f "dist/android/composeApp-release.apk" ]; then
        echo "  📱 composeApp-release.apk - Release version for production"
    fi
    
    if [ -f "dist/android/composeApp-release.aab" ]; then
        echo "  📦 composeApp-release.aab - App Bundle for Google Play Store"
    fi
    
    echo "  📄 INSTALL_INSTRUCTIONS.txt - Installation guide"
    
    if [ -f "dist/android/serve-apk.py" ]; then
        echo "  🌐 serve-apk.py - Local HTTP server for APK distribution"
    fi
    
    echo
    echo "Installation Options:"
    echo "  • Direct APK: Transfer APK to device and install"
    echo "  • ADB Install: adb install composeApp-debug.apk"
    echo "  • Local Server: python3 dist/android/serve-apk.py"
    echo "  • Play Store: Upload AAB file to Google Play Console"
    
    echo
    echo "Development:"
    echo "  • Setup IDE: ./setup-android-development.sh"
    echo "  • Edit code: composeApp/src/androidMain/kotlin/"
    echo "  • Rebuild: ./gradlew :composeApp:assembleDebug"
    
    echo
    echo "Configuration:"
    echo "  • Server URL: Configure in app settings"
    echo "  • Default server: http://localhost:8081"
    echo "  • Offline mode: Supported with local SQLite database"
    
    if command -v adb &> /dev/null; then
        DEVICES=$(adb devices | grep -v "List of devices" | grep "device$" | wc -l)
        if [ "$DEVICES" -gt 0 ]; then
            echo
            echo "Connected Devices: $DEVICES"
            echo "  • Install now: adb install -r dist/android/composeApp-debug.apk"
        fi
    fi
    
    echo
    print_status "Android app deployment completed successfully! 🚀"
}

# Main deployment process
main() {
    print_header "Starting Android App Deployment"
    
    detect_os
    check_java
    check_android_sdk
    configure_android_sdk
    generate_signing_key
    configure_gradle
    build_debug_apk
    build_release_apk
    build_app_bundle
    package_distribution
    create_dev_setup
    test_apk
    display_final_info
    
    echo
    print_status "Android app deployment completed successfully!"
    print_status "Your Android application is ready for distribution."
}

# Run main function
main "$@"
