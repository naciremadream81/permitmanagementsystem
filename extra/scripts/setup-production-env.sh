#!/bin/bash

# Production Environment Setup Script
# This script helps you create secure production environment variables

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$PROJECT_DIR/.env"

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

echo -e "${BLUE}🔧 Production Environment Setup${NC}"
echo "=================================="

# Check if .env already exists
if [ -f "$ENV_FILE" ]; then
    print_warning ".env file already exists"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Exiting without changes"
        exit 0
    fi
fi

# Generate secure JWT secret
print_info "Generating secure JWT secret..."
if command -v openssl &> /dev/null; then
    JWT_SECRET=$(openssl rand -base64 32)
    print_status "JWT secret generated securely"
else
    JWT_SECRET="$(date +%s | sha256sum | base64 | head -c 32)$(openssl rand -base64 16 2>/dev/null || echo 'fallback-secret')"
    print_warning "OpenSSL not found, using fallback method"
fi

# Get database configuration
echo ""
print_info "Database Configuration Options:"
echo "1. Use Docker PostgreSQL (recommended for testing)"
echo "2. Use external PostgreSQL database"
echo "3. Use existing database"

read -p "Choose option (1-3): " -n 1 -r DB_OPTION
echo ""

case $DB_OPTION in
    1)
        print_info "Using Docker PostgreSQL configuration"
        DATABASE_URL="jdbc:postgresql://db:5432/permit_management_prod"
        DB_USER="permit_user"
        read -s -p "Enter database password (will be hidden): " DB_PASSWORD
        echo ""
        ;;
    2)
        print_info "External PostgreSQL configuration"
        read -p "Enter database host (e.g., your-db-host.com): " DB_HOST
        read -p "Enter database port (default 5432): " DB_PORT
        DB_PORT=${DB_PORT:-5432}
        read -p "Enter database name (default permit_management_prod): " DB_NAME
        DB_NAME=${DB_NAME:-permit_management_prod}
        DATABASE_URL="jdbc:postgresql://$DB_HOST:$DB_PORT/$DB_NAME"
        read -p "Enter database username: " DB_USER
        read -s -p "Enter database password (will be hidden): " DB_PASSWORD
        echo ""
        ;;
    3)
        print_info "Custom database configuration"
        read -p "Enter full database URL: " DATABASE_URL
        read -p "Enter database username: " DB_USER
        read -s -p "Enter database password (will be hidden): " DB_PASSWORD
        echo ""
        ;;
    *)
        print_error "Invalid option"
        exit 1
        ;;
esac

# Get server configuration
echo ""
print_info "Server Configuration"
read -p "Enter server port (default 8080): " SERVER_PORT
SERVER_PORT=${SERVER_PORT:-8080}

read -p "Enter server host (default 0.0.0.0): " SERVER_HOST
SERVER_HOST=${SERVER_HOST:-0.0.0.0}

# Create .env file
print_info "Creating .env file..."

cat > "$ENV_FILE" << EOF
# Permit Management System - Production Environment
# Generated on $(date)

# Database Configuration
DATABASE_URL=$DATABASE_URL
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD

# JWT Configuration
JWT_SECRET=$JWT_SECRET

# Server Configuration
SERVER_PORT=$SERVER_PORT
SERVER_HOST=$SERVER_HOST
ENVIRONMENT=production

# File Upload Configuration
UPLOAD_MAX_SIZE=10485760
UPLOAD_DIR=./uploads

# Logging Configuration
LOG_LEVEL=INFO
LOG_FILE=./logs/server.log

# CORS Configuration (update with your domain)
CORS_ALLOWED_ORIGINS=http://localhost:3000,https://yourdomain.com

# SSL Configuration (configure if using HTTPS)
SSL_ENABLED=false
SSL_KEYSTORE_PATH=
SSL_KEYSTORE_PASSWORD=

# Database Pool Configuration
DB_POOL_SIZE=10
DB_CONNECTION_TIMEOUT=30000

# Session Configuration
SESSION_TIMEOUT=3600000

# Email Configuration (configure for notifications)
SMTP_HOST=
SMTP_PORT=587
SMTP_USER=
SMTP_PASSWORD=
SMTP_FROM=noreply@yourdomain.com

# Backup Configuration
BACKUP_ENABLED=true
BACKUP_SCHEDULE=0 2 * * *
BACKUP_RETENTION_DAYS=30
EOF

# Set secure permissions
chmod 600 "$ENV_FILE"

print_status "Production environment file created: $ENV_FILE"
print_warning "File permissions set to 600 (owner read/write only)"

echo ""
echo "=================================="
print_status "🎉 Production environment setup complete!"
echo ""
echo "Configuration Summary:"
echo "  - Database: $DATABASE_URL"
echo "  - Server: $SERVER_HOST:$SERVER_PORT"
echo "  - JWT Secret: Generated securely"
echo "  - Environment: production"
echo ""
echo "Next Steps:"
echo "  1. Review and edit .env if needed"
echo "  2. Deploy server: ./deploy-server.sh production"
echo "  3. Or use Docker: docker-compose -f docker-compose.simple.yml up -d"
echo ""
print_info "Your production environment is ready! 🚀"
