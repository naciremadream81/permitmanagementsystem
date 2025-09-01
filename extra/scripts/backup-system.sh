#!/bin/bash
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

echo "Creating system backup..."
docker-compose -f docker-compose.production.yml exec -T postgres pg_dump -U permit_user permit_management_prod | gzip > "$BACKUP_DIR/database_$DATE.sql.gz"
tar -czf "$BACKUP_DIR/uploads_$DATE.tar.gz" uploads/ 2>/dev/null || true
echo "Backup created: $BACKUP_DIR/database_$DATE.sql.gz"
