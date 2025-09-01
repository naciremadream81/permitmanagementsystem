#!/bin/bash

# Simple Database Maintenance Script
# Usage: ./db-maintenance.sh [action]

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Load environment
load_env() {
    if [ -f ".env" ]; then
        source .env
    elif [ -f ".env.production" ]; then
        source .env.production
    else
        print_error "No environment file found"
        exit 1
    fi
    
    # Extract database details
    DB_HOST=$(echo $DATABASE_URL | sed -n 's/.*:\/\/\([^:]*\).*/\1/p')
    DB_PORT=$(echo $DATABASE_URL | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
    DB_NAME=$(echo $DATABASE_URL | sed -n 's/.*\/\([^?]*\).*/\1/p')
}

# Create backup
backup() {
    print_info "Creating database backup..."
    mkdir -p backups
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="backups/${DB_NAME}_${timestamp}.sql"
    
    if PGPASSWORD=$DB_PASSWORD pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME > "$backup_file"; then
        gzip "$backup_file"
        print_status "Backup created: ${backup_file}.gz"
    else
        print_error "Backup failed"
        exit 1
    fi
}

# Health check
health() {
    print_info "Database health check..."
    
    if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
        print_status "Database connection: OK"
        
        # Get stats
        PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
        SELECT 
            'Database Size: ' || pg_size_pretty(pg_database_size('$DB_NAME')) as info
        UNION ALL
        SELECT 
            'Active Connections: ' || count(*)::text
        FROM pg_stat_activity 
        WHERE datname = '$DB_NAME';
        "
    else
        print_error "Database connection failed"
        exit 1
    fi
}

# Show usage
usage() {
    echo "Database Maintenance Script"
    echo ""
    echo "Usage: ./db-maintenance.sh [action]"
    echo ""
    echo "Actions:"
    echo "  backup    Create database backup"
    echo "  health    Check database health"
    echo "  help      Show this help"
    echo ""
}

# Main
case ${1:-help} in
    "backup")
        load_env
        backup
        ;;
    "health")
        load_env
        health
        ;;
    "help"|*)
        usage
        ;;
esac
