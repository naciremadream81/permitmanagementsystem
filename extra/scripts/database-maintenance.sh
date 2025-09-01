#!/bin/bash

# Permit Management System - Database Maintenance Script
# This script provides database maintenance operations
# Usage: ./database-maintenance.sh [action] [options]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Load environment variables
load_env() {
    if [ -f ".env" ]; then
        source .env
        print_info "Loaded environment from .env"
    elif [ -f ".env.production" ]; then
        source .env.production
        print_info "Loaded environment from .env.production"
    else
        print_error "No environment file found. Please create .env or .env.production"
        exit 1
    fi
    
    # Validate required variables
    if [ -z "$DATABASE_URL" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
        print_error "Missing required database environment variables"
        exit 1
    fi
    
    # Extract database details
    DB_HOST=$(echo $DATABASE_URL | sed -n 's/.*:\/\/\([^:]*\).*/\1/p')
    DB_PORT=$(echo $DATABASE_URL | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
    DB_NAME=$(echo $DATABASE_URL | sed -n 's/.*\/\([^?]*\).*/\1/p')
}

# Create backup with timestamp
create_backup() {
    local backup_type=${1:-"manual"}
    local backup_dir="backups"
    mkdir -p "$backup_dir"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$backup_dir/${DB_NAME}_${backup_type}_${timestamp}.sql"
    
    print_info "Creating $backup_type backup..."
    
    if PGPASSWORD=$DB_PASSWORD pg_dump \
        -h $DB_HOST -p $DB_PORT -U $DB_USER \
        -d $DB_NAME \
        --verbose \
        --no-owner \
        --no-privileges \
        > "$backup_file"; then
        
        # Compress backup
        gzip "$backup_file"
        local compressed_file="${backup_file}.gz"
        local file_size=$(du -h "$compressed_file" | cut -f1)
        
        print_status "Backup created: $compressed_file ($file_size)"
        echo "$compressed_file"
    else
        print_error "Backup failed"
        exit 1
    fi
}

# Restore from backup
restore_backup() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        print_error "Please specify backup file: ./database-maintenance.sh restore /path/to/backup.sql.gz"
        exit 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    print_warning "This will overwrite the current database. Continue? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_info "Restoring from backup: $backup_file"
        
        # Create a backup before restore
        print_info "Creating safety backup before restore..."
        create_backup "pre_restore" > /dev/null
        
        # Restore database
        if [[ "$backup_file" == *.gz ]]; then
            gunzip -c "$backup_file" | PGPASSWORD=$DB_PASSWORD psql \
                -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME \
                --quiet
        else
            PGPASSWORD=$DB_PASSWORD psql \
                -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME \
                --quiet < "$backup_file"
        fi
        
        print_status "Database restored successfully"
    else
        print_info "Restore cancelled"
    fi
}

# Database health check
health_check() {
    print_info "Performing database health check..."
    
    # Connection test
    if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
        print_status "Database connection: OK"
    else
        print_error "Database connection: FAILED"
        return 1
    fi
    
    # Get database statistics
    local stats=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "
        SELECT 
            pg_size_pretty(pg_database_size('$DB_NAME')) as db_size,
            (SELECT count(*) FROM pg_stat_activity WHERE datname='$DB_NAME') as active_connections,
            (SELECT count(*) FROM information_schema.tables WHERE table_schema='public') as table_count
    ")
    
    echo "Database Statistics:"
    echo "$stats" | while read -r line; do
        echo "  $line"
    done
    
    # Check table health
    print_info "Checking table statistics..."
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
        SELECT 
            tablename,
            n_live_tup as live_rows,
            n_dead_tup as dead_rows,
            last_vacuum,
            last_analyze
        FROM pg_stat_user_tables 
        ORDER BY n_live_tup DESC;
    "
}

# Optimize database performance
optimize_database() {
    print_info "Optimizing database performance..."
    
    # Update table statistics
    print_info "Updating table statistics..."
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "ANALYZE;"
    print_status "Table statistics updated"
    
    # Vacuum database
    print_info "Vacuuming database..."
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "VACUUM;"
    print_status "Database vacuumed"
    
    # Reindex if needed
    print_info "Checking for index bloat..."
    local bloated_indexes=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "
        SELECT count(*) FROM pg_stat_user_indexes 
        WHERE idx_scan = 0 AND schemaname = 'public';
    " | xargs)
    
    if [ "$bloated_indexes" -gt 0 ]; then
        print_warning "Found $bloated_indexes unused indexes"
        print_info "Consider running REINDEX if performance is degraded"
    else
        print_status "No unused indexes found"
    fi
}

# Clean up old data
cleanup_old_data() {
    local days=${1:-30}
    print_info "Cleaning up data older than $days days..."
    
    # This is a template - customize based on your data retention needs
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME << EOF
-- Example cleanup queries (customize as needed)
-- DELETE FROM audit_logs WHERE created_at < NOW() - INTERVAL '$days days';
-- DELETE FROM temporary_files WHERE created_at < NOW() - INTERVAL '$days days';

-- Show what would be cleaned up
SELECT 'permit_packages' as table_name, count(*) as old_records 
FROM permit_packages 
WHERE updated_at < NOW() - INTERVAL '$days days' AND status = 'completed';

SELECT 'permit_documents' as table_name, count(*) as old_records 
FROM permit_documents 
WHERE created_at < NOW() - INTERVAL '$days days';
EOF
    
    print_warning "Review the above results and customize cleanup queries in this script"
}

# Monitor database performance
monitor_performance() {
    print_info "Database performance monitoring..."
    
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME << 'EOF'
-- Current activity
SELECT 'Current Activity' as metric;
SELECT 
    datname,
    usename,
    application_name,
    state,
    query_start,
    left(query, 60) as query_preview
FROM pg_stat_activity 
WHERE datname = current_database()
AND state != 'idle'
ORDER BY query_start DESC
LIMIT 10;

-- Slow queries (if log_min_duration_statement is set)
SELECT 'Database Size' as metric;
SELECT pg_size_pretty(pg_database_size(current_database())) as database_size;

-- Table sizes
SELECT 'Largest Tables' as metric;
SELECT 
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;

-- Index usage
SELECT 'Index Usage' as metric;
SELECT 
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC
LIMIT 10;
EOF
}

# Setup automated backups
setup_automated_backups() {
    print_info "Setting up automated backups..."
    
    local backup_script="$PWD/automated-backup.sh"
    
    cat > "$backup_script" << 'EOF'
#!/bin/bash
# Automated backup script for Permit Management System

# Load environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ -f ".env" ]; then
    source .env
elif [ -f ".env.production" ]; then
    source .env.production
else
    echo "Error: No environment file found"
    exit 1
fi

# Create backup
./database-maintenance.sh backup

# Clean up old backups (keep last 30 days)
find backups/ -name "*.sql.gz" -mtime +30 -delete

# Log backup completion
echo "$(date): Automated backup completed" >> logs/backup.log
EOF
    
    chmod +x "$backup_script"
    print_status "Automated backup script created: $backup_script"
    
    # Create cron job suggestion
    print_info "To schedule daily backups at 2 AM, add this to your crontab:"
    echo "0 2 * * * cd $PWD && ./automated-backup.sh"
    print_info "Run 'crontab -e' to edit your cron jobs"
}

# Database migration (for schema changes)
migrate_database() {
    print_info "Running database migrations..."
    
    # Create migrations directory if it doesn't exist
    mkdir -p migrations
    
    # Example migration structure
    if [ ! -f "migrations/001_initial_schema.sql" ]; then
        cat > "migrations/001_initial_schema.sql" << 'EOF'
-- Initial schema migration
-- This file is automatically created by the application
-- Add your custom migrations here

-- Example: Add index for better performance
-- CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_permit_packages_user_id 
-- ON permit_packages(user_id);

-- Example: Add new column
-- ALTER TABLE permit_packages 
-- ADD COLUMN IF NOT EXISTS priority INTEGER DEFAULT 1;
EOF
        print_status "Created example migration file: migrations/001_initial_schema.sql"
    fi
    
    # Run migrations (customize as needed)
    for migration in migrations/*.sql; do
        if [ -f "$migration" ]; then
            print_info "Running migration: $(basename $migration)"
            PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$migration"
        fi
    done
    
    print_status "Migrations completed"
}

# Show usage information
show_usage() {
    echo "Database Maintenance Script for Permit Management System"
    echo ""
    echo "Usage: ./database-maintenance.sh [action] [options]"
    echo ""
    echo "Actions:"
    echo "  backup                    Create a manual backup"
    echo "  restore <backup_file>     Restore from backup file"
    echo "  health                    Perform health check"
    echo "  optimize                  Optimize database performance"
    echo "  cleanup [days]            Clean up old data (default: 30 days)"
    echo "  monitor                   Show performance monitoring info"
    echo "  setup-backups             Setup automated backup system"
    echo "  migrate                   Run database migrations"
    echo "  help                      Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./database-maintenance.sh backup"
    echo "  ./database-maintenance.sh restore backups/permit_management_prod_20240130_120000.sql.gz"
    echo "  ./database-maintenance.sh cleanup 60"
    echo ""
}

# Main function
main() {
    local action=${1:-help}
    
    case $action in
        "backup")
            load_env
            create_backup "manual"
            ;;
        "restore")
            load_env
            restore_backup "$2"
            ;;
        "health")
            load_env
            health_check
            ;;
        "optimize")
            load_env
            optimize_database
            ;;
        "cleanup")
            load_env
            cleanup_old_data "$2"
            ;;
        "monitor")
            load_env
            monitor_performance
            ;;
        "setup-backups")
            setup_automated_backups
            ;;
        "migrate")
            load_env
            migrate_database
            ;;
        "help"|*)
            show_usage
            ;;
    esac
}

# Run main function
main "$@"
