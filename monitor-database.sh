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
