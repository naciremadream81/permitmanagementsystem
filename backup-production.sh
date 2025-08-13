#!/bin/bash

set -e

# Configuration
ENV_FILE=".env.prod"
COMPOSE_FILE="docker-compose.prod.yml"
BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Load environment variables
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
else
    log_error "Environment file $ENV_FILE not found!"
    exit 1
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"

log_info "🗄️  Starting production backup..."

# Database backup
log_info "Backing up database..."
docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T postgres pg_dump \
    -U "${POSTGRES_USER:-permit_user}" \
    -d "${POSTGRES_DB:-permit_management_prod}" \
    --no-owner --no-privileges \
    > "$BACKUP_DIR/database_${TIMESTAMP}.sql"

# Compress database backup
gzip "$BACKUP_DIR/database_${TIMESTAMP}.sql"
log_info "Database backup saved: $BACKUP_DIR/database_${TIMESTAMP}.sql.gz"

# Backup uploads
if [[ -d "./uploads" && "$(ls -A ./uploads)" ]]; then
    log_info "Backing up uploads..."
    tar -czf "$BACKUP_DIR/uploads_${TIMESTAMP}.tar.gz" -C ./uploads .
    log_info "Uploads backup saved: $BACKUP_DIR/uploads_${TIMESTAMP}.tar.gz"
else
    log_warn "No uploads directory or empty uploads directory found"
fi

# Backup configuration
log_info "Backing up configuration..."
tar -czf "$BACKUP_DIR/config_${TIMESTAMP}.tar.gz" \
    --exclude="*.log" \
    --exclude="backups" \
    --exclude="uploads" \
    --exclude=".git" \
    --exclude="build" \
    --exclude=".gradle" \
    .

log_info "Configuration backup saved: $BACKUP_DIR/config_${TIMESTAMP}.tar.gz"

# Clean old backups (keep last 30 days)
log_info "Cleaning old backups..."
find "$BACKUP_DIR" -name "*.gz" -type f -mtime +30 -delete
find "$BACKUP_DIR" -name "*.sql" -type f -mtime +30 -delete

# Show backup summary
log_info "📊 Backup Summary:"
ls -lh "$BACKUP_DIR"/*${TIMESTAMP}*

log_info "✅ Backup completed successfully!"
