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
