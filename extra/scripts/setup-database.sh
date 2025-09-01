#!/bin/bash

# Permit Management System - Database Setup and Configuration Script
# This script sets up PostgreSQL database for production use
# Usage: ./setup-database.sh [environment] [action]
# Environment: production, staging, development (default: production)
# Action: install, configure, create, reset, backup, restore (default: install)

set -e  # Exit on any error

ENVIRONMENT=${1:-production}
ACTION=${2:-install}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🗄️  Permit Management System - Database Setup${NC}"
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

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            OS="debian"
            print_info "Detected Debian/Ubuntu system"
        elif [ -f /etc/redhat-release ]; then
            OS="redhat"
            print_info "Detected RedHat/CentOS/Fedora system"
        else
            OS="linux"
            print_info "Detected generic Linux system"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        print_info "Detected macOS system"
    else
        OS="unknown"
        print_warning "Unknown operating system: $OSTYPE"
    fi
}

# Install PostgreSQL
install_postgresql() {
    print_info "Installing PostgreSQL..."
    
    case $OS in
        "debian")
            sudo apt-get update
            sudo apt-get install -y postgresql postgresql-contrib postgresql-client
            ;;
        "redhat")
            sudo yum install -y postgresql-server postgresql-contrib postgresql
            # Initialize database on RedHat systems
            sudo postgresql-setup initdb
            ;;
        "macos")
            if command -v brew &> /dev/null; then
                brew install postgresql
            else
                print_error "Homebrew not found. Please install Homebrew first or install PostgreSQL manually"
                exit 1
            fi
            ;;
        *)
            print_error "Automatic PostgreSQL installation not supported for this OS"
            print_info "Please install PostgreSQL manually and run this script again"
            exit 1
            ;;
    esac
    
    print_status "PostgreSQL installation completed"
}

# Start PostgreSQL service
start_postgresql() {
    print_info "Starting PostgreSQL service..."
    
    case $OS in
        "debian")
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
            ;;
        "redhat")
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
            ;;
        "macos")
            if command -v brew &> /dev/null; then
                brew services start postgresql
            else
                pg_ctl -D /usr/local/var/postgres start
            fi
            ;;
    esac
    
    # Wait for PostgreSQL to start
    sleep 3
    print_status "PostgreSQL service started"
}

# Configure PostgreSQL for production
configure_postgresql() {
    print_info "Configuring PostgreSQL for $ENVIRONMENT..."
    
    # Find PostgreSQL configuration directory
    PG_VERSION=$(psql --version | awk '{print $3}' | sed 's/\..*//')
    
    case $OS in
        "debian")
            PG_CONFIG_DIR="/etc/postgresql/$PG_VERSION/main"
            ;;
        "redhat")
            PG_CONFIG_DIR="/var/lib/pgsql/data"
            ;;
        "macos")
            PG_CONFIG_DIR="/usr/local/var/postgres"
            if [ ! -d "$PG_CONFIG_DIR" ]; then
                PG_CONFIG_DIR="/opt/homebrew/var/postgres"
            fi
            ;;
    esac
    
    if [ ! -d "$PG_CONFIG_DIR" ]; then
        print_warning "PostgreSQL config directory not found at $PG_CONFIG_DIR"
        print_info "Please configure PostgreSQL manually"
        return
    fi
    
    print_info "PostgreSQL config directory: $PG_CONFIG_DIR"
    
    # Backup original configuration
    if [ -f "$PG_CONFIG_DIR/postgresql.conf" ]; then
        sudo cp "$PG_CONFIG_DIR/postgresql.conf" "$PG_CONFIG_DIR/postgresql.conf.backup.$(date +%Y%m%d)"
        print_status "Backed up postgresql.conf"
    fi
    
    if [ -f "$PG_CONFIG_DIR/pg_hba.conf" ]; then
        sudo cp "$PG_CONFIG_DIR/pg_hba.conf" "$PG_CONFIG_DIR/pg_hba.conf.backup.$(date +%Y%m%d)"
        print_status "Backed up pg_hba.conf"
    fi
    
    # Configure PostgreSQL settings for production
    if [ "$ENVIRONMENT" = "production" ]; then
        print_info "Applying production PostgreSQL configuration..."
        
        # Create optimized postgresql.conf settings
        cat > /tmp/postgresql_additions.conf << EOF

# Permit Management System - Production Settings
# Added on $(date)

# Connection Settings
max_connections = 100
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB

# Write Ahead Logging
wal_buffers = 16MB
checkpoint_completion_target = 0.9
wal_level = replica
max_wal_senders = 3

# Query Planner
random_page_cost = 1.1
effective_io_concurrency = 200

# Logging
log_destination = 'stderr'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 100MB
log_min_duration_statement = 1000
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on

# Security
ssl = on
password_encryption = scram-sha-256

EOF
        
        # Append to postgresql.conf
        sudo bash -c "cat /tmp/postgresql_additions.conf >> $PG_CONFIG_DIR/postgresql.conf"
        rm /tmp/postgresql_additions.conf
        print_status "Applied production PostgreSQL settings"
    fi
    
    print_status "PostgreSQL configuration completed"
}

# Create database user and database
create_database() {
    print_info "Creating database user and database..."
    
    # Switch to postgres user and create database user
    sudo -u postgres psql << EOF
-- Create user if not exists
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$DB_USER') THEN
        CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASSWORD';
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

-- Connect to the new database and set up permissions
\c $DB_NAME

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

# Restore database from backup
restore_database() {
    if [ -z "$BACKUP_FILE" ]; then
        print_error "Please specify backup file with: BACKUP_FILE=/path/to/backup.sql ./setup-database.sh $ENVIRONMENT restore"
        exit 1
    fi
    
    if [ ! -f "$BACKUP_FILE" ]; then
        print_error "Backup file not found: $BACKUP_FILE"
        exit 1
    fi
    
    print_info "Restoring database from: $BACKUP_FILE"
    print_warning "This will overwrite the existing database. Continue? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        # Drop and recreate database
        sudo -u postgres psql << EOF
DROP DATABASE IF EXISTS $DB_NAME;
CREATE DATABASE $DB_NAME OWNER $DB_USER;
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
EOF
        
        # Restore from backup
        if [[ "$BACKUP_FILE" == *.gz ]]; then
            gunzip -c "$BACKUP_FILE" | PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME
        else
            PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME < "$BACKUP_FILE"
        fi
        
        print_status "Database restored successfully"
    else
        print_info "Database restore cancelled"
    fi
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

# Setup database monitoring
setup_monitoring() {
    print_info "Setting up database monitoring..."
    
    # Create monitoring script
    cat > "$SCRIPT_DIR/monitor-database.sh" << 'EOF'
#!/bin/bash

# Database monitoring script
DB_NAME="${DB_NAME:-permit_management_prod}"
DB_USER="${DB_USER:-permit_user}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"

echo "=== Database Status ==="
echo "Date: $(date)"
echo "Database: $DB_NAME"
echo "Host: $DB_HOST:$DB_PORT"
echo ""

# Connection test
if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
    echo "✅ Database connection: OK"
else
    echo "❌ Database connection: FAILED"
    exit 1
fi

# Database size
DB_SIZE=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT pg_size_pretty(pg_database_size('$DB_NAME'));" | xargs)
echo "📊 Database size: $DB_SIZE"

# Active connections
ACTIVE_CONN=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT count(*) FROM pg_stat_activity WHERE datname='$DB_NAME';" | xargs)
echo "🔗 Active connections: $ACTIVE_CONN"

# Table counts
echo ""
echo "=== Table Statistics ==="
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
SELECT 
    schemaname,
    tablename,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes,
    n_live_tup as live_rows
FROM pg_stat_user_tables 
ORDER BY n_live_tup DESC;
"

echo ""
echo "=== Recent Activity ==="
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
SELECT 
    datname,
    usename,
    application_name,
    client_addr,
    state,
    query_start,
    left(query, 50) as query_preview
FROM pg_stat_activity 
WHERE datname = '$DB_NAME' 
AND state != 'idle'
ORDER BY query_start DESC
LIMIT 10;
"
EOF
    
    chmod +x "$SCRIPT_DIR/monitor-database.sh"
    print_status "Database monitoring script created: $SCRIPT_DIR/monitor-database.sh"
}

# Main function
main() {
    setup_database_config
    detect_os
    
    case $ACTION in
        "install")
            install_postgresql
            start_postgresql
            configure_postgresql
            create_database
            test_connection
            create_env_file
            setup_monitoring
            ;;
        "configure")
            configure_postgresql
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
        "restore")
            restore_database
            ;;
        "reset")
            reset_database
            ;;
        "monitor")
            setup_monitoring
            ;;
        *)
            print_error "Unknown action: $ACTION"
            echo "Available actions: install, configure, create, test, backup, restore, reset, monitor"
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
    echo "1. Review the environment file and update settings as needed"
    echo "2. Source the environment: source .env.$ENVIRONMENT"
    echo "3. Test the application: ./gradlew :server:run"
    echo "4. Monitor database: ./monitor-database.sh"
    echo ""
    print_status "Database is ready for use! 🚀"
}

# Run main function
main "$@"
