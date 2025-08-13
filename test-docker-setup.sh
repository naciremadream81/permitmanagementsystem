#!/bin/bash

echo "🧪 Testing Permit Management System Docker Setup"
echo "================================================"

# Check if containers are running
echo "📋 Checking container status..."
docker-compose ps

echo ""
echo "🔍 Testing API endpoints..."

# Test counties endpoint
echo "Testing /counties endpoint..."
COUNTIES_RESPONSE=$(curl -s http://localhost:8080/counties)
if [[ $? -eq 0 && "$COUNTIES_RESPONSE" == *"Miami-Dade County"* ]]; then
    echo "✅ Counties endpoint working - Response contains expected data"
else
    echo "❌ Counties endpoint failed"
    echo "Response: $COUNTIES_RESPONSE"
    exit 1
fi

# Test county checklist endpoint
echo "Testing /counties/1/checklist endpoint..."
CHECKLIST_RESPONSE=$(curl -s http://localhost:8080/counties/1/checklist)
if [[ $? -eq 0 && "$CHECKLIST_RESPONSE" == *"title"* ]]; then
    echo "✅ County checklist endpoint working - Response contains checklist data"
else
    echo "❌ County checklist endpoint failed"
    echo "Response: $CHECKLIST_RESPONSE"
    exit 1
fi

# Test database connection
echo "Testing database connection..."
DB_LOGS=$(docker-compose logs postgres | grep "database system is ready to accept connections")
if [[ -n "$DB_LOGS" ]]; then
    echo "✅ Database is running and accepting connections"
else
    echo "❌ Database connection issues"
    exit 1
fi

# Test server health
echo "Testing server health..."
SERVER_LOGS=$(docker-compose logs server | grep "Responding at http://0.0.0.0:8080")
if [[ -n "$SERVER_LOGS" ]]; then
    echo "✅ Server is running and responding"
else
    echo "❌ Server health check failed"
    exit 1
fi

echo ""
echo "🎉 All tests passed! Docker setup is working correctly."
echo ""
echo "📝 Available endpoints:"
echo "   - Counties: http://localhost:8080/counties"
echo "   - County checklist: http://localhost:8080/counties/{id}/checklist"
echo "   - Database: localhost:5432 (postgres/password)"
echo ""
echo "🐳 Container management:"
echo "   - Start: docker-compose up -d"
echo "   - Stop: docker-compose down"
echo "   - Logs: docker-compose logs [service]"
echo "   - Rebuild: docker-compose build"
