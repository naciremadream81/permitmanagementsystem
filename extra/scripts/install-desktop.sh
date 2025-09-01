#!/bin/bash

# Permit Management System - Desktop App Installation Script
# Supports: macOS, Linux, Windows (via WSL/Git Bash)

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Permit Management System"
APP_VERSION="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo -e "${BLUE}🖥️  $APP_NAME - Desktop Installation${NC}"
echo -e "${BLUE}Version: $APP_VERSION${NC}"
echo "=================================================="

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        ARCH=$(uname -m)
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        ARCH=$(uname -m)
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
        ARCH="x64"
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    
    print_info "Detected OS: $OS ($ARCH)"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Java
    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
        print_status "Java found: $JAVA_VERSION"
    else
        print_error "Java is required but not installed"
        echo "Please install Java 11 or higher:"
        case $OS in
            "macos")
                echo "  brew install openjdk@11"
                ;;
            "linux")
                echo "  sudo apt-get install openjdk-11-jdk  # Ubuntu/Debian"
                echo "  sudo yum install java-11-openjdk     # CentOS/RHEL"
                ;;
            "windows")
                echo "  Download from: https://adoptium.net/"
                ;;
        esac
        exit 1
    fi
    
    # Check Gradle (optional, we have gradlew)
    if command -v gradle &> /dev/null; then
        GRADLE_VERSION=$(gradle --version | grep "Gradle" | cut -d' ' -f2)
        print_status "Gradle found: $GRADLE_VERSION"
    else
        print_info "Using project's Gradle wrapper"
    fi
}

# Build desktop application
build_desktop_app() {
    print_status "Building desktop application..."
    cd "$PROJECT_DIR"
    
    # Clean previous builds
    ./gradlew clean
    
    # Build desktop application
    print_info "This may take a few minutes..."
    ./gradlew :composeApp:createDistributable
    
    if [ $? -eq 0 ]; then
        print_status "Desktop application built successfully"
    else
        print_error "Failed to build desktop application"
        exit 1
    fi
}

# Install on macOS
install_macos() {
    print_status "Installing on macOS..."
    
    APP_BUNDLE="$PROJECT_DIR/composeApp/build/compose/binaries/main/app/$APP_NAME.app"
    INSTALL_DIR="/Applications"
    
    if [ -d "$APP_BUNDLE" ]; then
        # Remove existing installation
        if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
            print_warning "Removing existing installation..."
            rm -rf "$INSTALL_DIR/$APP_NAME.app"
        fi
        
        # Copy to Applications
        cp -R "$APP_BUNDLE" "$INSTALL_DIR/"
        
        print_status "Installed to $INSTALL_DIR/$APP_NAME.app"
        
        # Create desktop shortcut
        create_macos_desktop_shortcut
        
        # Create dock shortcut
        print_info "You can now find '$APP_NAME' in your Applications folder"
        print_info "Drag it to your Dock for easy access"
        
    else
        print_error "Application bundle not found at: $APP_BUNDLE"
        exit 1
    fi
}

# Install on Linux
install_linux() {
    print_status "Installing on Linux..."
    
    APP_DIR="$PROJECT_DIR/composeApp/build/compose/binaries/main/app"
    INSTALL_DIR="$HOME/.local/share/applications"
    BIN_DIR="$HOME/.local/bin"
    
    # Create directories
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$BIN_DIR"
    mkdir -p "$HOME/.local/share/permit-management"
    
    # Copy application files
    cp -R "$APP_DIR"/* "$HOME/.local/share/permit-management/"
    
    # Create executable script
    cat > "$BIN_DIR/permit-management" << EOF
#!/bin/bash
cd "$HOME/.local/share/permit-management"
./bin/$APP_NAME "\$@"
EOF
    chmod +x "$BIN_DIR/permit-management"
    
    # Create desktop entry
    cat > "$INSTALL_DIR/permit-management.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$APP_NAME
Comment=Offline-first permit package management system
Exec=$BIN_DIR/permit-management
Icon=$HOME/.local/share/permit-management/icon.png
Terminal=false
Categories=Office;Development;
EOF
    
    chmod +x "$INSTALL_DIR/permit-management.desktop"
    
    print_status "Installed to $HOME/.local/share/permit-management"
    print_info "You can run the app with: permit-management"
    print_info "Or find it in your application menu"
}

# Install on Windows
install_windows() {
    print_status "Installing on Windows..."
    
    APP_DIR="$PROJECT_DIR/composeApp/build/compose/binaries/main/app"
    INSTALL_DIR="$HOME/AppData/Local/PermitManagement"
    
    # Create install directory
    mkdir -p "$INSTALL_DIR"
    
    # Copy application files
    cp -R "$APP_DIR"/* "$INSTALL_DIR/"
    
    # Create batch file for easy execution
    cat > "$HOME/Desktop/Permit Management System.bat" << EOF
@echo off
cd /d "$INSTALL_DIR"
start "" "bin\\$APP_NAME.exe"
EOF
    
    print_status "Installed to $INSTALL_DIR"
    print_info "Desktop shortcut created: Permit Management System.bat"
    print_info "You can also run from: $INSTALL_DIR/bin/$APP_NAME.exe"
}

# Create macOS desktop shortcut
create_macos_desktop_shortcut() {
    DESKTOP_DIR="$HOME/Desktop"
    if [ -d "$DESKTOP_DIR" ]; then
        ln -sf "/Applications/$APP_NAME.app" "$DESKTOP_DIR/$APP_NAME"
        print_status "Desktop shortcut created"
    fi
}

# Create uninstaller
create_uninstaller() {
    print_status "Creating uninstaller..."
    
    cat > "$PROJECT_DIR/uninstall-desktop.sh" << EOF
#!/bin/bash

# Permit Management System - Desktop Uninstaller

echo "🗑️  Uninstalling $APP_NAME..."

case "\$(uname -s)" in
    Darwin*)
        # macOS
        rm -rf "/Applications/$APP_NAME.app"
        rm -f "$HOME/Desktop/$APP_NAME"
        echo "✅ Uninstalled from macOS"
        ;;
    Linux*)
        # Linux
        rm -rf "$HOME/.local/share/permit-management"
        rm -f "$HOME/.local/bin/permit-management"
        rm -f "$HOME/.local/share/applications/permit-management.desktop"
        echo "✅ Uninstalled from Linux"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        # Windows
        rm -rf "$HOME/AppData/Local/PermitManagement"
        rm -f "$HOME/Desktop/Permit Management System.bat"
        echo "✅ Uninstalled from Windows"
        ;;
esac

echo "🎉 Uninstallation complete!"
EOF
    
    chmod +x "$PROJECT_DIR/uninstall-desktop.sh"
    print_status "Uninstaller created: ./uninstall-desktop.sh"
}

# Create app configuration
create_app_config() {
    print_status "Creating application configuration..."
    
    CONFIG_DIR=""
    case $OS in
        "macos")
            CONFIG_DIR="$HOME/Library/Application Support/PermitManagement"
            ;;
        "linux")
            CONFIG_DIR="$HOME/.config/permit-management"
            ;;
        "windows")
            CONFIG_DIR="$HOME/AppData/Roaming/PermitManagement"
            ;;
    esac
    
    mkdir -p "$CONFIG_DIR"
    
    # Create default configuration
    cat > "$CONFIG_DIR/config.properties" << EOF
# Permit Management System Configuration
server.url=http://localhost:8080
app.version=$APP_VERSION
offline.enabled=true
sync.interval=300000
log.level=INFO
EOF
    
    print_status "Configuration created at: $CONFIG_DIR"
}

# Main installation process
main() {
    detect_os
    check_prerequisites
    build_desktop_app
    
    case $OS in
        "macos")
            install_macos
            ;;
        "linux")
            install_linux
            ;;
        "windows")
            install_windows
            ;;
    esac
    
    create_app_config
    create_uninstaller
    
    echo "=================================================="
    print_status "🎉 Desktop installation completed successfully!"
    echo ""
    echo "Installation Summary:"
    echo "  - OS: $OS ($ARCH)"
    echo "  - Version: $APP_VERSION"
    case $OS in
        "macos")
            echo "  - Location: /Applications/$APP_NAME.app"
            echo "  - Desktop shortcut: Yes"
            ;;
        "linux")
            echo "  - Location: $HOME/.local/share/permit-management"
            echo "  - Command: permit-management"
            ;;
        "windows")
            echo "  - Location: $HOME/AppData/Local/PermitManagement"
            echo "  - Desktop shortcut: Yes"
            ;;
    esac
    echo ""
    echo "Next Steps:"
    echo "  1. Start the server: ./deploy-server.sh"
    echo "  2. Launch the desktop app"
    echo "  3. Configure server URL in app settings if needed"
    echo ""
    print_status "Desktop app is ready for production use! 🚀"
}

# Run main function
main "$@"
