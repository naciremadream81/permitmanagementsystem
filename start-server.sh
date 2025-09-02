#!/bin/bash

echo "🚀 Starting Permit Management System Server"
echo "============================================="

# Set environment variables
export DATABASE_URL="jdbc:postgresql://localhost:5432/permit_management_dev"
export DB_USER="permit_user"
export DB_PASSWORD="permit_password_2025"
export JWT_SECRET="supersecretjwtkeythatshouldbemorethan256bitslongandsecure"

echo "✅ Environment variables set"
echo "📊 Database: $DATABASE_URL"
echo "👤 User: $DB_USER"

# Start the server
echo "🔄 Starting server..."
./gradlew :server:run --no-daemon
