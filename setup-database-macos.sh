#!/bin/bash

# Permit Management System - macOS Database Setup Script
# This script sets up PostgreSQL database specifically for macOS systems
# Usage: ./setup-database-macos.sh [environment] [action]

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

echo -e "${BLUE}🗄️  Permit Management System - macOS Database Setup${NC}"
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

# Install PostgreSQL using Homebrew
install_postgresql() {
    print_info "Installing PostgreSQL via Homebrew..."
    
    if ! command -v brew &> /dev/null; then
        print_error "Homebrew not found. Please install Homebrew first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    
    # Install PostgreSQL
    brew install postgresql@14
    
    # Add PostgreSQL to PATH
    export PATH="/usr/local/opt/postgresql@14/bin:/opt/homebrew/opt/postgresql@14/bin:$PATH"
    
    print_status "PostgreSQL installation completed"
    print_info "PostgreSQL added to PATH for this session"
}

# Start PostgreSQL service
start_postgresql() {
    print_info "Starting PostgreSQL service..."
    
    # Start PostgreSQL service
    brew services start postgresql@14
    
    # Wait for PostgreSQL to start
    sleep 3
    
    # Test if PostgreSQL is running
    if pgrep -f postgres > /dev/null; then
        print_status "PostgreSQL service started successfully"
    else
        print_warning "PostgreSQL may not be running. Trying to start manually..."
        /usr/local/opt/postgresql@14/bin/postgres -D /usr/local/var/postgresql@14 &
        sleep 3
    fi
}

# Create database user and database (macOS version)
create_database() {
    print_info "Creating database user and database..."
    
    # On macOS, we connect as the current user (who has superuser privileges)
    # First, create the database user
    psql postgres << EOF
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
    psql $DB_NAME << EOF
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
        if ! pgrep -f postgres > /dev/null; then
            print_error "PostgreSQL is not running. Try: brew services start postgresql@14"
        fi
        
        # Check if we can connect as current user
        if psql postgres -c "SELECT 1;" > /dev/null 2>&1; then
            print_info "Can connect as current user, but not as $DB_USER"
            print_info "This might be a password or user creation issue"
        else
            print_error "Cannot connect to PostgreSQL at all"
        fi
        
        exit 1
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
        psql postgres << EOF
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

# Check PostgreSQL installation and paths
check_postgresql() {
    print_info "Checking PostgreSQL installation..."
    
    # Add common PostgreSQL paths to PATH
    export PATH="/usr/local/opt/postgresql@14/bin:/opt/homebrew/opt/postgresql@14/bin:$PATH"
    
    # Check if PostgreSQL is installed
    if command -v psql &> /dev/null; then
        PG_VERSION=$(psql --version | awk '{print $3}')
        print_status "PostgreSQL found: version $PG_VERSION"
    else
        # Check if PostgreSQL is installed via Homebrew but not in PATH
        if [ -f "/usr/local/opt/postgresql@14/bin/psql" ] || [ -f "/opt/homebrew/opt/postgresql@14/bin/psql" ]; then
            print_warning "PostgreSQL found but not in PATH. Adding to PATH..."
            print_status "PostgreSQL found: $(psql --version | awk '{print $3}')"
        else
            print_error "PostgreSQL not found"
            return 1
        fi
    fi
    
    # Check if PostgreSQL is running
    if pgrep -f postgres > /dev/null; then
        print_status "PostgreSQL is running"
    else
        print_warning "PostgreSQL is not running"
        print_info "Try: brew services start postgresql@14"
    fi
    
    # Check common PostgreSQL paths
    POSSIBLE_PATHS=(
        "/usr/local/var/postgresql@14"
        "/opt/homebrew/var/postgresql@14" 
        "/usr/local/var/postgres"
        "/opt/homebrew/var/postgres"
    )
    
    for path in "${POSSIBLE_PATHS[@]}"; do
        if [ -d "$path" ]; then
            print_info "Found PostgreSQL data directory: $path"
            break
        fi
    done
}

# Main function
main() {
    # Add PostgreSQL to PATH early in case it's already installed
    export PATH="/usr/local/opt/postgresql@14/bin:/opt/homebrew/opt/postgresql@14/bin:$PATH"
    
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
