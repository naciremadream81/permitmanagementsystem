#!/bin/bash

# Script to set up Java 17 for the Permit Management System
# This ensures Java 17 is available for Gradle builds

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo -e "${BLUE}☕ Java 17 Setup for Permit Management System${NC}"
echo "=================================================="

# Detect shell
SHELL_NAME=$(basename "$SHELL")
print_info "Detected shell: $SHELL_NAME"

# Determine config file
case $SHELL_NAME in
    "bash")
        CONFIG_FILE="$HOME/.bash_profile"
        if [ ! -f "$CONFIG_FILE" ]; then
            CONFIG_FILE="$HOME/.bashrc"
        fi
        ;;
    "zsh")
        CONFIG_FILE="$HOME/.zshrc"
        ;;
    *)
        CONFIG_FILE="$HOME/.profile"
        print_warning "Unknown shell, using .profile"
        ;;
esac

print_info "Using config file: $CONFIG_FILE"

# Java 17 paths
JAVA17_HOME="/usr/local/opt/openjdk@17"
JAVA17_BIN="/usr/local/opt/openjdk@17/bin"

# Check if Java 17 is installed
if [ ! -d "$JAVA17_HOME" ]; then
    print_error "Java 17 not found at $JAVA17_HOME"
    print_info "Installing Java 17 via Homebrew..."
    brew install openjdk@17
fi

# Check if Java configuration already exists
if grep -q "openjdk@17" "$CONFIG_FILE" 2>/dev/null; then
    print_warning "Java 17 configuration already exists in $CONFIG_FILE"
    print_info "Current Java configuration:"
    grep -A2 -B2 "openjdk@17" "$CONFIG_FILE"
else
    # Add Java 17 configuration
    echo "" >> "$CONFIG_FILE"
    echo "# Java 17 Configuration - Added by setup-java.sh on $(date)" >> "$CONFIG_FILE"
    echo "export JAVA_HOME=\"$JAVA17_HOME\"" >> "$CONFIG_FILE"
    echo "export PATH=\"$JAVA17_BIN:\$PATH\"" >> "$CONFIG_FILE"
    
    print_status "Added Java 17 configuration to $CONFIG_FILE"
fi

# Set for current session
export JAVA_HOME="$JAVA17_HOME"
export PATH="$JAVA17_BIN:$PATH"

# Test Java installation
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n1 | awk -F '"' '{print $2}')
    print_status "Java is now available: version $JAVA_VERSION"
    
    # Check if it's Java 17
    if [[ "$JAVA_VERSION" == 17.* ]]; then
        print_status "Java 17 is correctly configured"
    else
        print_warning "Java version is $JAVA_VERSION, but Java 17 is required"
        print_info "You may need to restart your terminal or run: source $CONFIG_FILE"
    fi
else
    print_error "Java still not found in PATH"
    exit 1
fi

# Test Gradle compatibility
print_info "Testing Gradle compatibility..."
if command -v ./gradlew &> /dev/null; then
    print_info "Gradle wrapper found, testing Java compatibility..."
    # This will show if Gradle can use Java 17
    ./gradlew --version | head -n 10
    print_status "Gradle should now work with Java 17"
else
    print_info "Gradle wrapper not found in current directory"
fi

echo ""
echo "=================================================="
print_status "Java 17 setup completed!"
echo ""
echo "Java Information:"
echo "  - Version: $(java -version 2>&1 | head -n1)"
echo "  - JAVA_HOME: $JAVA_HOME"
echo "  - Java Binary: $(which java)"
echo ""
echo "To use Java 17 in your current terminal:"
echo "  source $CONFIG_FILE"
echo ""
echo "Or open a new terminal window."
echo ""
print_info "Your Permit Management System should now build successfully!"
