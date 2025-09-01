#!/bin/bash
echo "=== Permit Management System Monitor ==="
echo "Date: $(date)"
echo

# Container status
echo "Container Status:"
docker-compose -f docker-compose.production.yml ps

echo
echo "Resource Usage:"
docker stats --no-stream

echo
echo "Disk Usage:"
df -h .

echo
echo "Service Health:"
if curl -sf http://localhost:8081/counties > /dev/null; then
    echo "✅ API: Healthy"
else
    echo "❌ API: Failed"
fi

if docker-compose -f docker-compose.production.yml exec -T postgres pg_isready -U permit_user > /dev/null 2>&1; then
    echo "✅ Database: Healthy"
else
    echo "❌ Database: Failed"
fi

if docker-compose -f docker-compose.production.yml exec -T redis redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis: Healthy"
else
    echo "❌ Redis: Failed"
fi
