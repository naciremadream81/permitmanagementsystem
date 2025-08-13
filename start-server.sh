#!/bin/bash
echo "Starting Permit Management System..."
docker-compose -f docker-compose.production.yml up -d
echo "System started. Access at: http://localhost:8081"
