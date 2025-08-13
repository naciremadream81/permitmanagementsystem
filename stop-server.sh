#!/bin/bash
echo "Stopping Permit Management System..."
docker-compose -f docker-compose.production.yml down
echo "System stopped."
