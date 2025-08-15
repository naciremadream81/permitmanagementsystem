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
