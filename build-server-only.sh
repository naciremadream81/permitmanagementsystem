#!/bin/bash

# Build script for server-only development
# This script builds only the server and shared modules, skipping Android targets

set -e

echo "🔧 Building server-only components..."

# Set environment variables to skip Android
export ANDROID_HOME=""
export ANDROID_SDK_ROOT=""

# Build only server and shared modules
echo "📦 Building shared module..."
./gradlew :shared:build --no-daemon

echo "🚀 Building server module..."
./gradlew :server:build --no-daemon

echo "✅ Server-only build completed successfully!"
echo ""
echo "📋 Available commands:"
echo "  ./gradlew :server:run          # Run the server"
echo "  ./gradlew :server:shadowJar    # Create executable JAR"
echo "  ./gradlew :server:test         # Run server tests"
echo ""
echo "🌐 To start the server:"
echo "  ./gradlew :server:run"
echo ""
echo "📱 For full build (including Android), install Android SDK and run:"
echo "  ./gradlew build"
