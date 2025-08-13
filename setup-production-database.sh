#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${BLUE}$1${NC}"
}

# Configuration
DB_NAME="permit_management_prod"
DB_USER="permit_user"
DB_PASSWORD=""
POSTGRES_VERSION=""

# Generate secure password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Check if PostgreSQL is installed and running
check_postgresql() {
    if ! command -v psql &> /dev/null; then
        log_error "PostgreSQL is not installed. Please install it first:"
        log_info "sudo apt install postgresql postgresql-contrib"
        exit 1
    fi

    if ! sudo systemctl is-active --quiet postgresql; then
        log_warn "PostgreSQL is not running. Starting it..."
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
    fi

    POSTGRES_VERSION=$(sudo -u postgres psql -t -c "SELECT version();" | head -1 | awk '{print $2}')
    log_info "PostgreSQL version: $POSTGRES_VERSION"
}

# Create database and user
setup_database() {
    log_info "Creating database and user..."

    # Generate secure password
    DB_PASSWORD=$(generate_password)
    
    # Create user and database
    sudo -u postgres psql << EOF
-- Create user if not exists
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$DB_USER') THEN
        CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASSWORD';
    ELSE
        ALTER ROLE $DB_USER WITH PASSWORD '$DB_PASSWORD';
    END IF;
END
\$\$;

-- Create database if not exists
SELECT 'CREATE DATABASE $DB_NAME OWNER $DB_USER'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME')\gexec

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
ALTER DATABASE $DB_NAME OWNER TO $DB_USER;
EOF

    log_info "✅ Database '$DB_NAME' and user '$DB_USER' created successfully"
}

# Test database connection
test_connection() {
    log_info "Testing database connection..."
    
    if PGPASSWORD="$DB_PASSWORD" psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
        log_info "✅ Database connection successful"
    else
        log_error "❌ Database connection failed"
        exit 1
    fi
}

# Configure PostgreSQL for production
configure_postgresql() {
    log_info "Configuring PostgreSQL for production..."
    
    # Find PostgreSQL config directory
    PG_VERSION=$(sudo -u postgres psql -t -c "SHOW server_version_num;" | tr -d ' ' | head -c 2)
    PG_CONFIG_DIR="/etc/postgresql/$PG_VERSION/main"
    
    if [[ ! -d "$PG_CONFIG_DIR" ]]; then
        # Try alternative paths
        PG_CONFIG_DIR=$(sudo -u postgres psql -t -c "SHOW config_file;" | tr -d ' ' | xargs dirname)
    fi
    
    log_info "PostgreSQL config directory: $PG_CONFIG_DIR"
    
    # Backup original configs
    sudo cp "$PG_CONFIG_DIR/postgresql.conf" "$PG_CONFIG_DIR/postgresql.conf.backup" 2>/dev/null || true
    sudo cp "$PG_CONFIG_DIR/pg_hba.conf" "$PG_CONFIG_DIR/pg_hba.conf.backup" 2>/dev/null || true
    
    # Update postgresql.conf for production
    sudo tee -a "$PG_CONFIG_DIR/postgresql.conf" > /dev/null << EOF

# Production optimizations added by setup script
listen_addresses = 'localhost'
max_connections = 100
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 4MB
min_wal_size = 1GB
max_wal_size = 4GB
EOF

    # Ensure proper authentication
    if ! sudo grep -q "host $DB_NAME $DB_USER 127.0.0.1/32 md5" "$PG_CONFIG_DIR/pg_hba.conf"; then
        sudo sed -i "/^# IPv4 local connections:/a host $DB_NAME $DB_USER 127.0.0.1/32 md5" "$PG_CONFIG_DIR/pg_hba.conf"
    fi
    
    # Restart PostgreSQL to apply changes
    sudo systemctl restart postgresql
    
    log_info "✅ PostgreSQL configured for production"
}

# Create environment file
create_env_file() {
    log_info "Creating production environment file..."
    
    cat > .env.prod.local << EOF
# Production Environment Configuration
# Generated on $(date)

# Database Configuration
POSTGRES_DB=$DB_NAME
POSTGRES_USER=$DB_USER
POSTGRES_PASSWORD=$DB_PASSWORD

# JWT Configuration (MUST be at least 32 characters)
JWT_SECRET=$(openssl rand -base64 48 | tr -d "=+/" | cut -c1-32)

# Server Configuration
SERVER_PORT=8080
SERVER_HOST=0.0.0.0
ENVIRONMENT=production
LOG_LEVEL=INFO

# File Upload Configuration
UPLOAD_MAX_SIZE=10485760
UPLOAD_DIR=/app/uploads

# CORS Configuration (update with your domain)
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://app.yourdomain.com

# Domain Configuration (update with your domain)
DOMAIN=yourdomain.com
SSL_EMAIL=admin@yourdomain.com

# Backup Configuration
BACKUP_ENABLED=true
BACKUP_RETENTION_DAYS=30
EOF

    chmod 600 .env.prod.local
    log_info "✅ Environment file created: .env.prod.local"
}

# Create database backup script
create_backup_script() {
    log_info "Setting up database backup..."
    
    mkdir -p backups
    
    cat > backup-db.sh << 'EOF'
#!/bin/bash
# Database backup script

set -e

# Load environment
if [[ -f .env.prod.local ]]; then
    source .env.prod.local
else
    echo "Error: .env.prod.local not found"
    exit 1
fi

# Create backup
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="backups/database_${TIMESTAMP}.sql"

echo "Creating database backup..."
PGPASSWORD="$POSTGRES_PASSWORD" pg_dump -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB" > "$BACKUP_FILE"

# Compress backup
gzip "$BACKUP_FILE"
echo "Backup created: ${BACKUP_FILE}.gz"

# Clean old backups (keep last 30 days)
find backups/ -name "database_*.sql.gz" -mtime +30 -delete
echo "Old backups cleaned"
EOF

    chmod +x backup-db.sh
    log_info "✅ Backup script created: backup-db.sh"
}

# Main execution
main() {
    log_header "🗄️  Permit Management System - Production Database Setup"
    log_header "======================================================="
    
    check_postgresql
    setup_database
    test_connection
    configure_postgresql
    create_env_file
    create_backup_script
    
    log_header "\n🎉 Production Database Setup Complete!"
    log_header "======================================"
    
    log_info "📝 Database Details:"
    log_info "   Database: $DB_NAME"
    log_info "   User: $DB_USER"
    log_info "   Password: $DB_PASSWORD"
    log_info "   Host: localhost"
    log_info "   Port: 5432"
    
    log_info "\n📁 Files Created:"
    log_info "   .env.prod.local - Production environment configuration"
    log_info "   backup-db.sh - Database backup script"
    
    log_info "\n🚀 Next Steps:"
    log_info "   1. Review and update .env.prod.local with your domain"
    log_info "   2. Set up SSL certificates in nginx/ssl/"
    log_info "   3. Run: ./deploy-production.sh"
    log_info "   4. Set up automated backups: crontab -e"
    log_info "      Add: 0 2 * * * /path/to/backup-db.sh"
    
    log_info "\n🔒 Security Notes:"
    log_info "   - Keep .env.prod.local secure (chmod 600)"
    log_info "   - Use strong passwords in production"
    log_info "   - Configure firewall to restrict database access"
    log_info "   - Set up SSL certificates for HTTPS"
    
    log_warn "\n⚠️  Important: Update CORS_ALLOWED_ORIGINS and DOMAIN in .env.prod.local"
}

# Run main function
main "$@"
