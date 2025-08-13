#!/bin/bash

# Simple Desktop App Runner for Permit Management System
echo "🖥️  Starting Desktop Application..."

# Set environment variables
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export API_BASE_URL=http://localhost:8081

# Check if production server is running
if curl -s http://localhost:8081/counties > /dev/null; then
    echo "✅ Production server is running"
else
    echo "❌ Production server is not running"
    echo "Please start the production server first:"
    echo "  docker compose -f docker-compose.production.yml up -d"
    exit 1
fi

# Try to build and run the desktop app
echo "🔨 Building desktop application..."

# Skip Android-related tasks
./gradlew :composeApp:runDistributable \
    -x :shared:extractDebugAnnotations \
    -x :shared:extractReleaseAnnotations \
    -x :shared:bundleDebugAar \
    -x :shared:bundleReleaseAar \
    -x :composeApp:extractDebugAnnotations \
    -x :composeApp:extractReleaseAnnotations \
    -x :composeApp:bundleDebugAar \
    -x :composeApp:bundleReleaseAar \
    --exclude-task extractDebugAnnotations \
    --exclude-task extractReleaseAnnotations \
    --exclude-task bundleDebugAar \
    --exclude-task bundleReleaseAar

echo "Desktop app should now be running!"
