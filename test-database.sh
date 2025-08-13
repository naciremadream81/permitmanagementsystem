#!/bin/bash

echo "=== PostgreSQL Database Test ==="
echo ""

# Test database connection
echo "1. Testing database connection..."
/usr/local/opt/postgresql@15/bin/psql -h localhost -U postgres -d permit_management -c "SELECT version();" || {
    echo "❌ Database connection failed"
    exit 1
}
echo "✅ Database connection successful"
echo ""

# Test tables
echo "2. Testing database tables..."
/usr/local/opt/postgresql@15/bin/psql -h localhost -U postgres -d permit_management -c "\dt" || {
    echo "❌ Failed to list tables"
    exit 1
}
echo "✅ Database tables exist"
echo ""

# Test counties data
echo "3. Testing counties data..."
COUNTY_COUNT=$(/usr/local/opt/postgresql@15/bin/psql -h localhost -U postgres -d permit_management -t -c "SELECT COUNT(*) FROM counties;")
echo "Counties in database: $COUNTY_COUNT"
if [ "$COUNTY_COUNT" -gt 0 ]; then
    echo "✅ Counties data exists"
else
    echo "❌ No counties data found"
fi
echo ""

# Test API endpoints
echo "4. Testing API endpoints..."
echo "Root endpoint:"
curl -s http://localhost:8080/ || echo "❌ Root endpoint failed"
echo ""

echo "Counties endpoint (first 3):"
curl -s http://localhost:8080/counties | head -20 || echo "❌ Counties endpoint failed"
echo ""

echo "=== Database Test Complete ==="
