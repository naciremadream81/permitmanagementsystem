#!/bin/bash

# Production Test Script for Permit Management System
set -e

echo "🧪 Testing Production Deployment..."

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Test 1: Container Health
print_test "Checking container health..."
if docker compose -f docker-compose.production.yml ps | grep -q "healthy"; then
    print_success "All containers are healthy"
else
    print_error "Some containers are not healthy"
    docker compose -f docker-compose.production.yml ps
    exit 1
fi

# Test 2: Web App Access
print_test "Testing web app access..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8081 | grep -q "200"; then
    print_success "Web app is accessible"
else
    print_error "Web app is not accessible"
    exit 1
fi

# Test 3: Counties API
print_test "Testing counties API..."
response=$(curl -s http://localhost:8081/counties)
if echo "$response" | grep -q "Miami-Dade County"; then
    print_success "Counties API is working"
    county_count=$(echo "$response" | grep -o '"id"' | wc -l)
    echo "  Found $county_count counties"
else
    print_error "Counties API is not working"
    echo "Response: $response"
    exit 1
fi

# Test 4: County Checklist API
print_test "Testing county checklist API..."
checklist_response=$(curl -s http://localhost:8081/counties/1/checklist)
if echo "$checklist_response" | grep -q "Building Permit Application"; then
    print_success "County checklist API is working"
    item_count=$(echo "$checklist_response" | grep -o '"id"' | wc -l)
    echo "  Found $item_count checklist items for Miami-Dade County"
else
    print_error "County checklist API is not working"
    echo "Response: $checklist_response"
    exit 1
fi

# Test 5: Database Connection
print_test "Testing database connection..."
if docker exec permit-db-prod pg_isready -U permit_user -d permit_management_prod > /dev/null 2>&1; then
    print_success "Database is accessible"
else
    print_error "Database is not accessible"
    exit 1
fi

# Test 6: Redis Connection
print_test "Testing Redis connection..."
if docker exec permit-redis-prod redis-cli ping | grep -q "PONG"; then
    print_success "Redis is accessible"
else
    print_error "Redis is not accessible"
    exit 1
fi

# Test 7: Admin Panel
print_test "Testing admin panel..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/admin | grep -q "200"; then
    print_success "Admin panel is accessible"
else
    print_error "Admin panel is not accessible"
fi

# Performance Test
print_test "Running performance test..."
start_time=$(date +%s%N)
curl -s http://localhost:8081/counties > /dev/null
end_time=$(date +%s%N)
response_time=$(( (end_time - start_time) / 1000000 ))
if [ $response_time -lt 1000 ]; then
    print_success "API response time: ${response_time}ms (Good)"
elif [ $response_time -lt 2000 ]; then
    print_success "API response time: ${response_time}ms (Acceptable)"
else
    print_error "API response time: ${response_time}ms (Slow)"
fi

echo ""
echo "🎉 Production deployment test completed successfully!"
echo ""
echo "📊 Summary:"
echo "  - Web App: http://localhost:8081"
echo "  - Admin Panel: http://localhost:8081/admin"
echo "  - API Base: http://localhost:8081/counties"
echo "  - Database: localhost:5433"
echo ""
echo "🔧 Management Commands:"
echo "  - View logs: docker compose -f docker-compose.production.yml logs -f"
echo "  - Stop services: docker compose -f docker-compose.production.yml down"
echo "  - Restart services: docker compose -f docker-compose.production.yml restart"
echo ""
