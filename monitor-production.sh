#!/bin/bash

# Configuration
ENV_FILE=".env.prod"
COMPOSE_FILE="docker-compose.prod.yml"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
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

log_header() {
    echo -e "${BLUE}$1${NC}"
}

clear
log_header "🔍 Permit Management System - Production Monitor"
log_header "=============================================="

# Check if services are running
log_header "\n📊 Container Status:"
docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps

# Check resource usage
log_header "\n💾 Resource Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"

# Check disk usage
log_header "\n💿 Disk Usage:"
df -h | grep -E "(Filesystem|/dev/)"
echo ""
du -sh ./uploads ./logs ./backups 2>/dev/null || echo "Some directories not found"

# Check service health
log_header "\n🏥 Health Checks:"

# Test database
if docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T postgres pg_isready -U "${POSTGRES_USER:-permit_user}" > /dev/null 2>&1; then
    log_info "✅ Database is healthy"
else
    log_error "❌ Database is not responding"
fi

# Test API
if curl -k -f -s "http://localhost:8080/counties" > /dev/null 2>&1; then
    log_info "✅ API is responding"
else
    log_error "❌ API is not responding"
fi

# Test nginx (if running)
if docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps nginx | grep -q "Up"; then
    if curl -k -f -s "https://localhost/health" > /dev/null 2>&1; then
        log_info "✅ Nginx proxy is healthy"
    else
        log_error "❌ Nginx proxy is not responding"
    fi
fi

# Check logs for errors
log_header "\n📋 Recent Errors (last 50 lines):"
docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs --tail=50 | grep -i error || log_info "No recent errors found"

# Show recent activity
log_header "\n📈 Recent Activity (last 20 lines):"
docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs --tail=20

# Database stats
log_header "\n🗄️  Database Statistics:"
if docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T postgres psql -U "${POSTGRES_USER:-permit_user}" -d "${POSTGRES_DB:-permit_management_prod}" -c "
SELECT 
    schemaname,
    tablename,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes
FROM pg_stat_user_tables 
ORDER BY n_tup_ins DESC;" 2>/dev/null; then
    echo ""
else
    log_warn "Could not retrieve database statistics"
fi

# Show backup status
log_header "\n💾 Backup Status:"
if [[ -d "./backups" ]]; then
    LATEST_BACKUP=$(ls -t ./backups/database_*.sql.gz 2>/dev/null | head -1)
    if [[ -n "$LATEST_BACKUP" ]]; then
        BACKUP_DATE=$(stat -c %y "$LATEST_BACKUP" 2>/dev/null | cut -d' ' -f1)
        log_info "Latest backup: $LATEST_BACKUP ($BACKUP_DATE)"
    else
        log_warn "No database backups found"
    fi
    
    BACKUP_SIZE=$(du -sh ./backups 2>/dev/null | cut -f1)
    log_info "Backup directory size: $BACKUP_SIZE"
else
    log_warn "Backup directory not found"
fi

log_header "\n🔧 Quick Commands:"
echo "  View logs:     docker-compose -f $COMPOSE_FILE --env-file $ENV_FILE logs [service]"
echo "  Restart:       docker-compose -f $COMPOSE_FILE --env-file $ENV_FILE restart [service]"
echo "  Scale:         docker-compose -f $COMPOSE_FILE --env-file $ENV_FILE up -d --scale server=2"
echo "  Backup:        ./backup-production.sh"
echo "  Update:        ./deploy-production.sh"

echo ""
