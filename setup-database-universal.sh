#!/bin/bash

# Permit Management System - Universal Database Setup Script
# This script detects your operating system and runs the appropriate setup script
# Usage: ./setup-database-universal.sh [environment] [action]

set -e  # Exit on any error

ENVIRONMENT=${1:-development}
ACTION=${2:-install}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🗄️  Permit Management System - Universal Database Setup${NC}"
echo -e "${BLUE}Environment: $ENVIRONMENT | Action: $ACTION${NC}"
echo "=================================================="

# Function to print colored output
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

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO_NAME="$PRETTY_NAME"
        else
            DISTRO_NAME="Linux"
        fi
        print_info "Detected: $DISTRO_NAME"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        MACOS_VERSION=$(sw_vers -productVersion)
        print_info "Detected: macOS $MACOS_VERSION"
    else
        OS="unknown"
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
}

# Run the appropriate setup script
run_setup_script() {
    case $OS in
        "macos")
            SETUP_SCRIPT="$SCRIPT_DIR/setup-database-macos.sh"
            if [ ! -f "$SETUP_SCRIPT" ]; then
                print_error "macOS setup script not found: $SETUP_SCRIPT"
                exit 1
            fi
            print_info "Running macOS database setup script..."
            "$SETUP_SCRIPT" "$ENVIRONMENT" "$ACTION"
            ;;
        "linux")
            SETUP_SCRIPT="$SCRIPT_DIR/setup-database-linux.sh"
            if [ ! -f "$SETUP_SCRIPT" ]; then
                print_error "Linux setup script not found: $SETUP_SCRIPT"
                exit 1
            fi
            print_info "Running Linux database setup script..."
            "$SETUP_SCRIPT" "$ENVIRONMENT" "$ACTION"
            ;;
        *)
            print_error "No setup script available for OS: $OS"
            exit 1
            ;;
    esac
}

# Show usage information
show_usage() {
    echo ""
    echo "Usage: $0 [environment] [action]"
    echo ""
    echo "Environments:"
    echo "  development  - Development environment (default)"
    echo "  staging      - Staging environment"
    echo "  production   - Production environment"
    echo ""
    echo "Actions:"
    echo "  install      - Full installation (default)"
    echo "  create       - Create database only"
    echo "  test         - Test database connection"
    echo "  backup       - Create database backup"
    echo "  reset        - Reset database (WARNING: deletes data)"
    echo "  check        - Check PostgreSQL installation"
    echo ""
    echo "Examples:"
    echo "  $0                           # Install development environment"
    echo "  $0 production install        # Install production environment"
    echo "  $0 development test          # Test development database"
    echo "  $0 production backup         # Backup production database"
    echo ""
}

# Check if help was requested
if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "help" ]]; then
    show_usage
    exit 0
fi

# Main execution
main() {
    detect_os
    
    print_info "Selected environment: $ENVIRONMENT"
    print_info "Selected action: $ACTION"
    echo ""
    
    run_setup_script
}

# Run main function
main "$@"
