#!/bin/bash
echo "=== Permit Management System Status ==="
docker-compose -f docker-compose.production.yml ps
echo
echo "=== Service Health ==="
if curl -sf http://localhost:8081/counties > /dev/null; then
    echo "✅ API: Healthy"
else
    echo "❌ API: Failed"
fi
