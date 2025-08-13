#!/bin/bash

# Permit Management System - Production Server Deployment Script
# Usage: ./deploy-server.sh [environment]
# Environment: production, staging, development (default: production)

set -e  # Exit on any error

ENVIRONMENT=${1:-production}
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$PROJECT_DIR/logs"
PID_FILE="$PROJECT_DIR/server.pid"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Permit Management System - Production Server Deployment${NC}"
echo -e "${BLUE}Environment: $ENVIRONMENT${NC}"
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

# Check if server is already running
check_server_status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            print_warning "Server is already running (PID: $PID)"
            echo "Use './stop-server.sh' to stop the current server first"
            exit 1
        else
            print_warning "Stale PID file found, removing..."
            rm -f "$PID_FILE"
        fi
    fi
}

# Create necessary directories
setup_directories() {
    print_status "Setting up directories..."
    mkdir -p "$LOG_DIR"
    mkdir -p "$PROJECT_DIR/uploads"
    mkdir -p "$PROJECT_DIR/data"
}

# Set production environment variables
setup_environment() {
    print_status "Setting up environment variables..."
    
    # Default production values
    export DATABASE_URL=${DATABASE_URL:-"jdbc:postgresql://localhost:5432/permit_management_prod"}
    export DB_USER=${DB_USER:-"permit_user"}
    export DB_PASSWORD=${DB_PASSWORD:-""}
    export JWT_SECRET=${JWT_SECRET:-""}
    export SERVER_PORT=${SERVER_PORT:-8080}
    export SERVER_HOST=${SERVER_HOST:-"0.0.0.0"}
    export ENVIRONMENT=$ENVIRONMENT
    
    # Check required environment variables
    if [ -z "$DB_PASSWORD" ]; then
        print_error "DB_PASSWORD environment variable is required for production"
        echo "Set it with: export DB_PASSWORD='your-secure-password'"
        exit 1
    fi
    
    if [ -z "$JWT_SECRET" ]; then
        print_error "JWT_SECRET environment variable is required for production"
        echo "Set it with: export JWT_SECRET='your-secure-jwt-secret-key'"
        exit 1
    fi
    
    print_status "Environment configured for $ENVIRONMENT"
    echo "  - Database: $DATABASE_URL"
    echo "  - Server: $SERVER_HOST:$SERVER_PORT"
    echo "  - Uploads: $PROJECT_DIR/uploads"
}

# Build the server
build_server() {
    print_status "Building server for production..."
    cd "$PROJECT_DIR"
    
    # Clean previous builds
    ./gradlew clean
    
    # Build server
    ./gradlew :server:build
    
    if [ $? -eq 0 ]; then
        print_status "Server build completed successfully"
    else
        print_error "Server build failed"
        exit 1
    fi
}

# Start database if using Docker
start_database() {
    if [ "$ENVIRONMENT" = "development" ] || [ "$ENVIRONMENT" = "staging" ]; then
        print_status "Starting database with Docker Compose..."
        if command -v docker-compose &> /dev/null; then
            docker-compose up -d db
            sleep 5  # Wait for database to be ready
        else
            print_warning "Docker Compose not found, assuming external database"
        fi
    fi
}

# Run database migrations/setup
setup_database() {
    print_status "Setting up database..."
    # Database setup is handled by the application on startup
    # You could add explicit migration scripts here if needed
}

# Start the server
start_server() {
    print_status "Starting server in production mode..."
    cd "$PROJECT_DIR"
    
    # Start server in background
    nohup ./gradlew :server:run \
        --args="--port=$SERVER_PORT --host=$SERVER_HOST" \
        > "$LOG_DIR/server.log" 2>&1 &
    
    SERVER_PID=$!
    echo $SERVER_PID > "$PID_FILE"
    
    print_status "Server started with PID: $SERVER_PID"
    print_status "Logs: $LOG_DIR/server.log"
    
    # Wait a moment and check if server started successfully
    sleep 5
    if ps -p $SERVER_PID > /dev/null 2>&1; then
        print_status "Server is running successfully"
        
        # Test server endpoint
        if command -v curl &> /dev/null; then
            echo "Testing server endpoint..."
            if curl -s "http://localhost:$SERVER_PORT/" > /dev/null; then
                print_status "Server is responding to requests"
            else
                print_warning "Server may still be starting up..."
            fi
        fi
    else
        print_error "Server failed to start"
        cat "$LOG_DIR/server.log"
        exit 1
    fi
}

# Setup log rotation
setup_log_rotation() {
    print_status "Setting up log rotation..."
    
    # Create logrotate configuration
    cat > "$PROJECT_DIR/logrotate.conf" << EOF
$LOG_DIR/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 $(whoami) $(whoami)
    postrotate
        # Restart server if needed
        if [ -f "$PID_FILE" ]; then
            kill -USR1 \$(cat "$PID_FILE") 2>/dev/null || true
        fi
    endscript
}
EOF
    
    print_status "Log rotation configured"
}

# Create systemd service file (Linux)
create_systemd_service() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        print_status "Creating systemd service file..."
        
        cat > "/tmp/permit-management.service" << EOF
[Unit]
Description=Permit Management System Server
After=network.target

[Service]
Type=forking
User=$(whoami)
WorkingDirectory=$PROJECT_DIR
Environment=DATABASE_URL=$DATABASE_URL
Environment=DB_USER=$DB_USER
Environment=DB_PASSWORD=$DB_PASSWORD
Environment=JWT_SECRET=$JWT_SECRET
Environment=SERVER_PORT=$SERVER_PORT
Environment=SERVER_HOST=$SERVER_HOST
Environment=ENVIRONMENT=$ENVIRONMENT
ExecStart=$PROJECT_DIR/deploy-server.sh
ExecStop=$PROJECT_DIR/stop-server.sh
PIDFile=$PID_FILE
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
        
        print_status "Systemd service file created at /tmp/permit-management.service"
        print_warning "To install: sudo mv /tmp/permit-management.service /etc/systemd/system/"
        print_warning "Then run: sudo systemctl enable permit-management && sudo systemctl start permit-management"
    fi
}

# Main deployment process
main() {
    echo "Starting deployment process..."
    
    check_server_status
    setup_directories
    setup_environment
    build_server
    start_database
    setup_database
    start_server
    setup_log_rotation
    create_systemd_service
    
    echo "=================================================="
    print_status "🎉 Server deployment completed successfully!"
    echo ""
    echo "Server Information:"
    echo "  - URL: http://$SERVER_HOST:$SERVER_PORT"
    echo "  - PID: $(cat $PID_FILE)"
    echo "  - Logs: $LOG_DIR/server.log"
    echo "  - Environment: $ENVIRONMENT"
    echo ""
    echo "Management Commands:"
    echo "  - Stop server: ./stop-server.sh"
    echo "  - View logs: tail -f $LOG_DIR/server.log"
    echo "  - Check status: ps -p \$(cat $PID_FILE)"
    echo ""
    print_status "Server is ready for production use! 🚀"
}

# Run main function
main "$@"
