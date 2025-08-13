#!/bin/bash

# Script to permanently add PostgreSQL to PATH on macOS
# This ensures PostgreSQL commands are available in all terminal sessions

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

echo -e "${BLUE}🔧 PostgreSQL PATH Setup for macOS${NC}"
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

# PostgreSQL paths to add
PG_PATHS=(
    "/usr/local/opt/postgresql@14/bin"
    "/opt/homebrew/opt/postgresql@14/bin"
)

# Check which PostgreSQL installation exists
PG_PATH=""
for path in "${PG_PATHS[@]}"; do
    if [ -d "$path" ]; then
        PG_PATH="$path"
        print_info "Found PostgreSQL at: $path"
        break
    fi
done

if [ -z "$PG_PATH" ]; then
    print_error "PostgreSQL installation not found"
    print_info "Please install PostgreSQL first: brew install postgresql@14"
    exit 1
fi

# Check if PATH is already configured
if grep -q "postgresql@14/bin" "$CONFIG_FILE" 2>/dev/null; then
    print_warning "PostgreSQL PATH already configured in $CONFIG_FILE"
    print_info "Current PATH configuration:"
    grep "postgresql@14" "$CONFIG_FILE"
else
    # Add PostgreSQL to PATH
    echo "" >> "$CONFIG_FILE"
    echo "# PostgreSQL PATH - Added by setup-postgresql-path.sh on $(date)" >> "$CONFIG_FILE"
    echo "export PATH=\"$PG_PATH:\$PATH\"" >> "$CONFIG_FILE"
    
    print_status "Added PostgreSQL to PATH in $CONFIG_FILE"
fi

# Also add to current session
export PATH="$PG_PATH:$PATH"

# Test PostgreSQL
if command -v psql &> /dev/null; then
    PG_VERSION=$(psql --version | awk '{print $3}')
    print_status "PostgreSQL is now available: version $PG_VERSION"
else
    print_error "PostgreSQL still not found in PATH"
    exit 1
fi

echo ""
echo "=================================================="
print_status "PostgreSQL PATH setup completed!"
echo ""
echo "To use PostgreSQL in your current terminal:"
echo "  source $CONFIG_FILE"
echo ""
echo "Or open a new terminal window."
echo ""
print_info "PostgreSQL commands are now available: psql, pg_dump, createdb, etc."
