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
