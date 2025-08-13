#!/bin/bash

# Permit Management System - Linux Database Setup Script
# This script sets up PostgreSQL database specifically for Linux systems (Debian/Ubuntu/Kali)
# Usage: ./setup-database-linux.sh [environment] [action]

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

echo -e "${BLUE}🗄️  Permit Management System - Linux Database Setup${NC}"
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

# Database configuration based on environment
setup_database_config() {
    case $ENVIRONMENT in
        "production")
            DB_NAME="permit_management_prod"
            DB_USER="permit_user"
            DB_PORT="5432"
            DB_HOST="localhost"
            ;;
        "staging")
            DB_NAME="permit_management_staging"
            DB_USER="permit_user_staging"
            DB_PORT="5432"
            DB_HOST="localhost"
            ;;
        "development")
            DB_NAME="permit_management_dev"
            DB_USER="permit_user_dev"
            DB_PORT="5432"
            DB_HOST="localhost"
            ;;
        *)
            print_error "Unknown environment: $ENVIRONMENT"
            exit 1
            ;;
    esac
    
    # Generate secure password if not provided
    if [ -z "$DB_PASSWORD" ]; then
        DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
        print_info "Generated secure database password"
    fi
    
    DATABASE_URL="jdbc:postgresql://$DB_HOST:$DB_PORT/$DB_NAME"
}

# Detect Linux distribution
detect_linux_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
        print_info "Detected Linux distribution: $PRETTY_NAME"
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
        print_info "Detected Debian-based system"
    else
        DISTRO="unknown"
        print_warning "Unknown Linux distribution"
    fi
}

# Install PostgreSQL on Linux
install_postgresql() {
    print_info "Installing PostgreSQL..."
    
    case $DISTRO in
        "ubuntu"|"debian"|"kali")
            # Update package list
            sudo apt-get update
            
            # Install PostgreSQL and contrib packages
            sudo apt-get install -y postgresql postgresql-contrib postgresql-client
            
            print_status "PostgreSQL installation completed"
            ;;
        "fedora"|"centos"|"rhel")
            # Install PostgreSQL
            sudo dnf install -y postgresql-server postgresql-contrib postgresql
            
            # Initialize database on RedHat-based systems
            sudo postgresql-setup --initdb
            
            print_status "PostgreSQL installation completed"
            ;;
        *)
            print_error "Automatic PostgreSQL installation not supported for this distribution"
            print_info "Please install PostgreSQL manually:"
            echo "  - For Debian/Ubuntu: sudo apt-get install postgresql postgresql-contrib"
            echo "  - For RHEL/CentOS: sudo dnf install postgresql-server postgresql-contrib"
            exit 1
            ;;
    esac
}

# Start PostgreSQL service on Linux
start_postgresql() {
    print_info "Starting PostgreSQL service..."
    
    # Start and enable PostgreSQL service
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    
    # Wait for PostgreSQL to start
    sleep 3
    
    # Check if PostgreSQL is running
    if sudo systemctl is-active --quiet postgresql; then
        print_status "PostgreSQL service started successfully"
    else
        print_error "Failed to start PostgreSQL service"
        print_info "Check the service status: sudo systemctl status postgresql"
        exit 1
    fi
}

# Create database user and database (Linux version)
create_database() {
    print_info "Creating database user and database..."
    
    # On Linux, we need to switch to the postgres user
    sudo -u postgres psql << EOF
-- Create user if not exists
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$DB_USER') THEN
        CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASSWORD';
        RAISE NOTICE 'Created user: $DB_USER';
    ELSE
        RAISE NOTICE 'User already exists: $DB_USER';
    END IF;
END
\$\$;

-- Grant necessary privileges
ALTER ROLE $DB_USER CREATEDB;

-- Create database if not exists
SELECT 'CREATE DATABASE $DB_NAME OWNER $DB_USER'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME')\gexec

-- Grant all privileges on database
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
EOF

    # Connect to the new database and set up permissions
    sudo -u postgres psql $DB_NAME << EOF
-- Grant schema permissions
GRANT ALL ON SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;
EOF
    
    print_status "Database user '$DB_USER' and database '$DB_NAME' created"
}

# Test database connection
test_connection() {
    print_info "Testing database connection..."
    
    if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT version();" > /dev/null 2>&1; then
        print_status "Database connection test successful"
        
        # Get PostgreSQL version
        PG_VERSION_FULL=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT version();" | head -n1 | xargs)
        print_info "Connected to: $PG_VERSION_FULL"
    else
        print_error "Database connection test failed"
        print_info "Trying to diagnose the issue..."
        
        # Check if PostgreSQL is running
        if ! sudo systemctl is-active --quiet postgresql; then
            print_error "PostgreSQL service is not running. Try: sudo systemctl start postgresql"
        fi
        
        # Check if we can connect as postgres user
        if sudo -u postgres psql -c "SELECT 1;" > /dev/null 2>&1; then
            print_info "Can connect as postgres user, but not as $DB_USER"
            print_info "This might be a password or user creation issue"
        else
            print_error "Cannot connect to PostgreSQL at all"
        fi
        
        exit 1
    fi
}

# Configure PostgreSQL for better security (Linux)
configure_postgresql_security() {
    print_info "Configuring PostgreSQL security settings..."
    
    # Find PostgreSQL version and config directory
    PG_VERSION=$(psql --version | awk '{print $3}' | sed 's/\..*//')
    PG_CONFIG_DIR="/etc/postgresql/$PG_VERSION/main"
    
    # Alternative paths for different distributions
    if [ ! -d "$PG_CONFIG_DIR" ]; then
        PG_CONFIG_DIR="/var/lib/pgsql/data"
    fi
    
    if [ ! -d "$PG_CONFIG_DIR" ]; then
        print_warning "PostgreSQL config directory not found"
        print_info "Skipping security configuration"
        return
    fi
    
    print_info "PostgreSQL config directory: $PG_CONFIG_DIR"
    
    # Backup original pg_hba.conf
    if [ -f "$PG_CONFIG_DIR/pg_hba.conf" ]; then
        sudo cp "$PG_CONFIG_DIR/pg_hba.conf" "$PG_CONFIG_DIR/pg_hba.conf.backup.$(date +%Y%m%d)"
        print_status "Backed up pg_hba.conf"
        
        # Add our application user to pg_hba.conf if not already present
        if ! sudo grep -q "$DB_USER" "$PG_CONFIG_DIR/pg_hba.conf"; then
            echo "# Permit Management System user" | sudo tee -a "$PG_CONFIG_DIR/pg_hba.conf"
            echo "local   $DB_NAME    $DB_USER                                md5" | sudo tee -a "$PG_CONFIG_DIR/pg_hba.conf"
            echo "host    $DB_NAME    $DB_USER    127.0.0.1/32               md5" | sudo tee -a "$PG_CONFIG_DIR/pg_hba.conf"
            print_status "Added database user to pg_hba.conf"
            
            # Reload PostgreSQL configuration
            sudo systemctl reload postgresql
            print_status "Reloaded PostgreSQL configuration"
        fi
    fi
}

# Create environment file
create_env_file() {
    print_info "Creating environment configuration file..."
    
    ENV_FILE="$SCRIPT_DIR/.env.$ENVIRONMENT"
    
    cat > "$ENV_FILE" << EOF
# Permit Management System - $ENVIRONMENT Environment
# Database Configuration - Generated on $(date)

DATABASE_URL=$DATABASE_URL
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_NAME=$DB_NAME

# Server Configuration
SERVER_PORT=8080
SERVER_HOST=0.0.0.0
ENVIRONMENT=$ENVIRONMENT

# JWT Configuration (CHANGE THIS IN PRODUCTION!)
JWT_SECRET=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)

# CORS Configuration
CORS_ALLOWED_ORIGINS=http://localhost:3000,https://yourdomain.com

# File Upload Configuration
UPLOAD_MAX_SIZE=10485760
UPLOAD_DIR=./uploads

# Logging Configuration
LOG_LEVEL=INFO
LOG_FILE=./logs/server.log

# Database Pool Configuration
DB_POOL_SIZE=10
DB_CONNECTION_TIMEOUT=30000
EOF
    
    chmod 600 "$ENV_FILE"  # Secure the file
    print_status "Environment file created: $ENV_FILE"
    print_warning "Please review and update the JWT_SECRET and other settings as needed"
}

# Reset database (drop and recreate)
reset_database() {
    print_warning "This will completely reset the database and all data will be lost!"
    print_warning "Continue? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_info "Resetting database..."
        
        # Drop database
        sudo -u postgres psql << EOF
DROP DATABASE IF EXISTS $DB_NAME;
EOF
        
        # Recreate database
        create_database
        print_status "Database reset completed"
    else
        print_info "Database reset cancelled"
    fi
}

# Backup database
backup_database() {
    print_info "Creating database backup..."
    
    BACKUP_DIR="$SCRIPT_DIR/backups"
    mkdir -p "$BACKUP_DIR"
    
    BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_backup_$(date +%Y%m%d_%H%M%S).sql"
    
    if PGPASSWORD=$DB_PASSWORD pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME > "$BACKUP_FILE"; then
        print_status "Database backup created: $BACKUP_FILE"
        
        # Compress the backup
        gzip "$BACKUP_FILE"
        print_status "Backup compressed: $BACKUP_FILE.gz"
    else
        print_error "Database backup failed"
        exit 1
    fi
}

# Check PostgreSQL installation and status
check_postgresql() {
    print_info "Checking PostgreSQL installation..."
    
    # Check if PostgreSQL is installed
    if command -v psql &> /dev/null; then
        PG_VERSION=$(psql --version | awk '{print $3}')
        print_status "PostgreSQL found: version $PG_VERSION"
    else
        print_error "PostgreSQL not found in PATH"
        return 1
    fi
    
    # Check if PostgreSQL service is running
    if sudo systemctl is-active --quiet postgresql; then
        print_status "PostgreSQL service is running"
    else
        print_warning "PostgreSQL service is not running"
        print_info "Try: sudo systemctl start postgresql"
    fi
    
    # Check if we can connect as postgres user
    if sudo -u postgres psql -c "SELECT 1;" > /dev/null 2>&1; then
        print_status "Can connect to PostgreSQL as postgres user"
    else
        print_error "Cannot connect to PostgreSQL as postgres user"
    fi
}

# Main function
main() {
    detect_linux_distro
    setup_database_config
    
    case $ACTION in
        "install")
            check_postgresql
            if ! command -v psql &> /dev/null; then
                install_postgresql
            else
                print_info "PostgreSQL already installed, skipping installation"
            fi
            start_postgresql
            create_database
            configure_postgresql_security
            test_connection
            create_env_file
            ;;
        "create")
            create_database
            test_connection
            create_env_file
            ;;
        "test")
            test_connection
            ;;
        "backup")
            backup_database
            ;;
        "reset")
            reset_database
            ;;
        "check")
            check_postgresql
            ;;
        *)
            print_error "Unknown action: $ACTION"
            echo "Available actions: install, create, test, backup, reset, check"
            exit 1
            ;;
    esac
    
    echo ""
    echo "=================================================="
    print_status "Database setup completed successfully!"
    echo ""
    echo "Database Information:"
    echo "  - Name: $DB_NAME"
    echo "  - User: $DB_USER"
    echo "  - Host: $DB_HOST:$DB_PORT"
    echo "  - URL: $DATABASE_URL"
    echo ""
    echo "Environment file: .env.$ENVIRONMENT"
    echo ""
    echo "Next steps:"
    echo "1. Review the environment file: cat .env.$ENVIRONMENT"
    echo "2. Source the environment: source .env.$ENVIRONMENT"
    echo "3. Test the application: ./gradlew :server:run"
    echo ""
    print_status "Database is ready for use! 🚀"
}

# Run main function
main "$@"
