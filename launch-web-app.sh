#!/bin/bash

# Web App Launcher for Permit Management System
# Serves the web applications from extra/web-apps/ directory

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

WEB_APPS_DIR="extra/web-apps"
PORT=3000

echo -e "${BLUE}🌐 Permit Management System - Web App Launcher${NC}"
echo -e "${BLUE}===============================================${NC}"
echo ""

# Function to check if Python is available
check_python() {
    if command -v python3 >/dev/null 2>&1; then
        echo "python3"
    elif command -v python >/dev/null 2>&1; then
        echo "python"
    else
        return 1
    fi
}

# Function to check if Node.js is available
check_node() {
    if command -v node >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to check if PHP is available
check_php() {
    if command -v php >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to list available web apps
list_web_apps() {
    echo -e "${YELLOW}📱 Available Web Applications:${NC}"
    echo ""
    
    if [ -d "$WEB_APPS_DIR" ]; then
        local count=0
        for file in "$WEB_APPS_DIR"/*.html; do
            if [ -f "$file" ]; then
                local basename=$(basename "$file")
                local name=$(echo "$basename" | sed 's/\.html$//' | sed 's/web-app-//' | sed 's/-/ /g')
                count=$((count + 1))
                echo -e "  ${GREEN}$count.${NC} $name"
                echo -e "     File: ${BLUE}$basename${NC}"
            fi
        done
        echo ""
        echo -e "Total: ${GREEN}$count${NC} web applications found"
    else
        echo -e "${RED}❌ Web apps directory not found: $WEB_APPS_DIR${NC}"
        exit 1
    fi
}

# Function to start web server with Python
start_python_server() {
    local python_cmd=$1
    echo -e "${YELLOW}🐍 Starting Python HTTP server...${NC}"
    echo -e "Serving from: ${GREEN}$WEB_APPS_DIR${NC}"
    echo -e "Port: ${GREEN}$PORT${NC}"
    echo ""
    echo -e "${BLUE}🌐 Web applications available at:${NC}"
    echo -e "  ${GREEN}http://localhost:$PORT${NC}"
    echo ""
    echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
    echo ""
    
    cd "$WEB_APPS_DIR"
    $python_cmd -m http.server "$PORT"
}

# Function to start web server with Node.js
start_node_server() {
    echo -e "${YELLOW}🟢 Starting Node.js HTTP server...${NC}"
    echo -e "Serving from: ${GREEN}$WEB_APPS_DIR${NC}"
    echo -e "Port: ${GREEN}$PORT${NC}"
    echo ""
    echo -e "${BLUE}🌐 Web applications available at:${NC}"
    echo -e "  ${GREEN}http://localhost:$PORT${NC}"
    echo ""
    echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
    echo ""
    
    cd "$WEB_APPS_DIR"
    npx http-server -p "$PORT" -c-1
}

# Function to start web server with PHP
start_php_server() {
    echo -e "${YELLOW}🐘 Starting PHP HTTP server...${NC}"
    echo -e "Serving from: ${GREEN}$WEB_APPS_DIR${NC}"
    echo -e "Port: ${GREEN}$PORT${NC}"
    echo ""
    echo -e "${BLUE}🌐 Web applications available at:${NC}"
    echo -e "  ${GREEN}http://localhost:$PORT${NC}"
    echo ""
    echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
    echo ""
    
    cd "$WEB_APPS_DIR"
    php -S "localhost:$PORT"
}

# Function to show usage
show_usage() {
    echo -e "${YELLOW}Usage: $0 [OPTIONS]${NC}"
    echo ""
    echo -e "${BLUE}Options:${NC}"
    echo -e "  ${GREEN}-p, --port PORT${NC}     Port to serve on (default: 3000)"
    echo -e "  ${GREEN}-l, --list${NC}          List available web applications"
    echo -e "  ${GREEN}-h, --help${NC}          Show this help message"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo -e "  ${GREEN}$0${NC}                    # Start server on port 3000"
    echo -e "  ${GREEN}$0 -p 8080${NC}           # Start server on port 8080"
    echo -e "  ${GREEN}$0 --list${NC}            # List available web apps"
    echo ""
}

# Main execution
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--port)
                PORT="$2"
                shift 2
                ;;
            -l|--list)
                list_web_apps
                exit 0
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Unknown option: $1${NC}"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Check if web apps directory exists
    if [ ! -d "$WEB_APPS_DIR" ]; then
        echo -e "${RED}❌ Web apps directory not found: $WEB_APPS_DIR${NC}"
        echo -e "${YELLOW}Please make sure you're running this script from the project root.${NC}"
        exit 1
    fi
    
    # List available web apps
    list_web_apps
    
    # Check for available web servers
    if python_cmd=$(check_python); then
        echo -e "${GREEN}✅ Python found: $python_cmd${NC}"
        start_python_server "$python_cmd"
    elif check_node; then
        echo -e "${GREEN}✅ Node.js found${NC}"
        start_node_server
    elif check_php; then
        echo -e "${GREEN}✅ PHP found${NC}"
        start_php_server
    else
        echo -e "${RED}❌ No suitable web server found${NC}"
        echo -e "${YELLOW}Please install one of the following:${NC}"
        echo -e "  • Python 3 (python3)"
        echo -e "  • Node.js (node)"
        echo -e "  • PHP (php)"
        echo ""
        echo -e "${BLUE}Installation commands:${NC}"
        echo -e "  ${GREEN}Ubuntu/Debian:${NC} sudo apt install python3 nodejs php"
        echo -e "  ${GREEN}Arch Linux:${NC} sudo pacman -S python nodejs php"
        exit 1
    fi
}

# Run main function
main "$@"
