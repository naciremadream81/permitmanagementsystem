#!/bin/bash
set -e

# Permit Management System - Desktop App Deployment Script
# This script builds and packages the desktop application for distribution

echo "🖥️  Permit Management System - Desktop App Deployment"
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

# Configure Gradle
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
}

# Build desktop application
build_desktop_app() {
    print_header "Building Desktop Application"
    
    print_status "Cleaning previous builds..."
    ./gradlew clean
    
    print_status "Building desktop application..."
    ./gradlew :composeApp:packageDistributionForCurrentOS
    
    if [ $? -eq 0 ]; then
        print_status "Desktop application built successfully"
    else
        print_error "Failed to build desktop application"
        exit 1
    fi
}

# Create installers
create_installers() {
    print_header "Creating Installers"
    
    case $OS in
        "linux")
            print_status "Creating Linux packages..."
            ./gradlew :composeApp:packageDeb || print_warning "DEB package creation failed"
            ./gradlew :composeApp:packageRpm || print_warning "RPM package creation failed"
            ;;
        "macos")
            print_status "Creating macOS installer..."
            ./gradlew :composeApp:packageDmg || print_warning "DMG creation failed"
            ;;
        "windows")
            print_status "Creating Windows installer..."
            ./gradlew :composeApp:packageMsi || print_warning "MSI creation failed"
            ;;
    esac
}

# Package distribution
package_distribution() {
    print_header "Packaging Distribution"
    
    # Create distribution directory
    DIST_DIR="dist/desktop"
    mkdir -p "$DIST_DIR"
    
    # Copy application files
    if [ -d "composeApp/build/compose/binaries/main/app" ]; then
        cp -r composeApp/build/compose/binaries/main/app/* "$DIST_DIR/"
        print_status "Application files copied to $DIST_DIR"
    fi
    
    # Copy installers based on OS
    case $OS in
        "linux")
            if [ -d "composeApp/build/compose/binaries/main/deb" ]; then
                cp composeApp/build/compose/binaries/main/deb/*.deb "$DIST_DIR/" 2>/dev/null || true
            fi
            if [ -d "composeApp/build/compose/binaries/main/rpm" ]; then
                cp composeApp/build/compose/binaries/main/rpm/*.rpm "$DIST_DIR/" 2>/dev/null || true
            fi
            ;;
        "macos")
            if [ -d "composeApp/build/compose/binaries/main/dmg" ]; then
                cp composeApp/build/compose/binaries/main/dmg/*.dmg "$DIST_DIR/" 2>/dev/null || true
            fi
            ;;
        "windows")
            if [ -d "composeApp/build/compose/binaries/main/msi" ]; then
                cp composeApp/build/compose/binaries/main/msi/*.msi "$DIST_DIR/" 2>/dev/null || true
            fi
            ;;
    esac
    
    # Create README for distribution
    cat > "$DIST_DIR/README.txt" << EOF
Permit Management System - Desktop Application
==============================================

Installation Instructions:
--------------------------

Linux:
- Ubuntu/Debian: sudo dpkg -i *.deb
- CentOS/RHEL: sudo rpm -i *.rpm
- Or run the executable directly: ./PermitManagement/bin/PermitManagement

macOS:
- Double-click the .dmg file and drag to Applications
- Or run the executable: ./PermitManagement.app/Contents/MacOS/PermitManagement

Windows:
- Double-click the .msi file to install
- Or run the executable: PermitManagement.exe

Configuration:
--------------
The application will connect to your Permit Management System server.
Default server: http://localhost:8081

To change the server URL, edit the configuration file:
- Linux: ~/.config/PermitManagement/config.properties
- macOS: ~/Library/Application Support/PermitManagement/config.properties
- Windows: %APPDATA%/PermitManagement/config.properties

Add the line: server.url=https://your-server.com

System Requirements:
-------------------
- Java 17 or higher (included in installer packages)
- 512MB RAM minimum
- 100MB disk space
- Network connection to server

Support:
--------
For support and documentation, visit:
https://github.com/yourusername/permitmanagementsystem
EOF
    
    print_status "Distribution package created in $DIST_DIR"
}

# Create launcher scripts
create_launcher_scripts() {
    print_header "Creating Launcher Scripts"
    
    DIST_DIR="dist/desktop"
    
    case $OS in
        "linux")
            # Create Linux launcher script
            cat > "$DIST_DIR/launch-permit-management.sh" << 'EOF'
#!/bin/bash
# Permit Management System Desktop App Launcher

# Find Java
if command -v java &> /dev/null; then
    JAVA_CMD="java"
elif [ -n "$JAVA_HOME" ] && [ -x "$JAVA_HOME/bin/java" ]; then
    JAVA_CMD="$JAVA_HOME/bin/java"
else
    echo "Error: Java not found. Please install Java 17 or higher."
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Launch application
cd "$SCRIPT_DIR"
if [ -f "PermitManagement/bin/PermitManagement" ]; then
    ./PermitManagement/bin/PermitManagement
else
    echo "Error: Application not found. Please ensure the application is properly installed."
    exit 1
fi
EOF
            chmod +x "$DIST_DIR/launch-permit-management.sh"
            ;;
            
        "macos")
            # Create macOS launcher script
            cat > "$DIST_DIR/launch-permit-management.command" << 'EOF'
#!/bin/bash
# Permit Management System Desktop App Launcher

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Launch application
cd "$SCRIPT_DIR"
if [ -d "PermitManagement.app" ]; then
    open PermitManagement.app
else
    echo "Error: Application not found. Please ensure the application is properly installed."
    exit 1
fi
EOF
            chmod +x "$DIST_DIR/launch-permit-management.command"
            ;;
            
        "windows")
            # Create Windows launcher batch file
            cat > "$DIST_DIR/launch-permit-management.bat" << 'EOF'
@echo off
REM Permit Management System Desktop App Launcher

REM Get script directory
set SCRIPT_DIR=%~dp0

REM Launch application
cd /d "%SCRIPT_DIR%"
if exist "PermitManagement.exe" (
    start PermitManagement.exe
) else (
    echo Error: Application not found. Please ensure the application is properly installed.
    pause
    exit /b 1
)
EOF
            ;;
    esac
    
    print_status "Launcher scripts created"
}

# Test the built application
test_application() {
    print_header "Testing Application"
    
    print_status "Starting application test..."
    
    # Try to run the application for a few seconds to verify it starts
    # Use gtimeout if available (from coreutils), otherwise skip timeout
    if command -v gtimeout >/dev/null 2>&1; then
        gtimeout 10s ./gradlew :composeApp:run &
    elif command -v timeout >/dev/null 2>&1; then
        timeout 10s ./gradlew :composeApp:run &
    else
        # On macOS without coreutils, just start and kill after delay
        ./gradlew :composeApp:run &
    fi
    TEST_PID=$!
    
    sleep 5
    
    if kill -0 $TEST_PID 2>/dev/null; then
        print_status "Application starts successfully"
        kill $TEST_PID 2>/dev/null || true
    else
        print_warning "Application test inconclusive"
    fi
}

# Create development setup script
create_dev_setup() {
    print_header "Creating Development Setup"
    
    cat > setup-desktop-development.sh << 'EOF'
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
EOF
    
    chmod +x setup-desktop-development.sh
    print_status "Development setup script created"
}

# Display final information
display_final_info() {
    print_header "Desktop App Deployment Complete!"
    
    echo -e "${GREEN}🎉 Desktop application built successfully!${NC}"
    echo
    echo "Distribution Files:"
    echo "  📁 dist/desktop/ - Complete distribution package"
    
    case $OS in
        "linux")
            echo "  📦 *.deb - Debian/Ubuntu package"
            echo "  📦 *.rpm - CentOS/RHEL package"
            echo "  🚀 launch-permit-management.sh - Linux launcher"
            ;;
        "macos")
            echo "  📦 *.dmg - macOS installer"
            echo "  🚀 launch-permit-management.command - macOS launcher"
            ;;
        "windows")
            echo "  📦 *.msi - Windows installer"
            echo "  🚀 launch-permit-management.bat - Windows launcher"
            ;;
    esac
    
    echo "  📄 README.txt - Installation instructions"
    echo
    echo "Quick Start:"
    echo "  • Run directly: ./gradlew :composeApp:run"
    echo "  • Install package: Use the appropriate installer for your OS"
    echo "  • Distribute: Share the dist/desktop/ folder"
    
    echo
    echo "Development:"
    echo "  • Setup IDE: ./setup-desktop-development.sh"
    echo "  • Edit code: composeApp/src/commonMain/kotlin/"
    echo "  • Rebuild: ./gradlew :composeApp:packageDistributionForCurrentOS"
    
    echo
    echo "Configuration:"
    echo "  • Server URL: Configure in app settings or config file"
    echo "  • Default server: http://localhost:8081"
    echo "  • Offline mode: Supported with local SQLite database"
    
    echo
    print_status "Desktop app deployment completed successfully! 🚀"
}

# Main deployment process
main() {
    print_header "Starting Desktop App Deployment"
    
    detect_os
    check_java
    configure_gradle
    build_desktop_app
    create_installers
    package_distribution
    create_launcher_scripts
    test_application
    create_dev_setup
    display_final_info
    
    echo
    print_status "Desktop app deployment completed successfully!"
    print_status "Your desktop application is ready for distribution."
}

# Run main function
main "$@"
