# 🔧 Build Guide

## Overview

This guide provides instructions for building the Permit Management System in different configurations, from server-only development to full multi-platform builds.

## 🚀 Quick Start

### Server-Only Development (Recommended for Backend Development)

If you're working on the backend server and don't need Android/iOS builds:

```bash
# 1. Setup minimal Android SDK (satisfies Gradle requirements)
./setup-minimal-android.sh

# 2. Build server and shared modules
./gradlew :server:compileKotlin :shared:compileKotlinJvm

# 3. Create executable JAR
./gradlew :server:shadowJar

# 4. Run the server
./gradlew :server:run
```

### Full Multi-Platform Build

For complete builds including Android and iOS:

```bash
# 1. Install Android SDK
# Follow Android Studio setup or install via command line

# 2. Enable all modules
# Edit settings.gradle.kts and uncomment:
# include(":composeApp")

# 3. Build everything
./gradlew build
```

## 📋 Build Configurations

### 1. Server-Only Build

**Use Case**: Backend development, API testing, server deployment

```bash
# Compile server and shared modules
./gradlew :server:compileKotlin :shared:compileKotlinJvm

# Create executable JAR
./gradlew :server:shadowJar

# Run server
./gradlew :server:run
```

**Output**: 
- `server/build/libs/server-all.jar` - Executable JAR file
- Server runs on `http://localhost:8080`

### 2. Shared Module Build

**Use Case**: Testing shared business logic

```bash
# Build shared module for JVM
./gradlew :shared:compileKotlinJvm

# Build shared module for all targets (requires Android SDK)
./gradlew :shared:build
```

### 3. Full Multi-Platform Build

**Use Case**: Complete application with all platforms

```bash
# Build everything (requires Android SDK and Xcode for iOS)
./gradlew build
```

**Output**:
- Android APK: `composeApp/build/outputs/apk/`
- Desktop JAR: `composeApp/build/libs/`
- iOS Framework: `composeApp/build/bin/`

## 🛠️ Prerequisites

### For Server-Only Development
- ✅ Java 21+
- ✅ PostgreSQL 13+ (for database)
- ✅ Git

### For Full Multi-Platform Build
- ✅ Java 21+
- ✅ Android SDK (API 34+)
- ✅ Xcode (for iOS builds)
- ✅ PostgreSQL 13+

## 🔧 Environment Setup

### 1. Java Setup
```bash
# Check Java version
java -version

# Should show Java 21 or higher
```

### 2. Android SDK Setup (Optional)
```bash
# Install Android SDK via Android Studio or command line
# Set environment variables
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# Or use the minimal setup script
./setup-minimal-android.sh
```

### 3. Database Setup
```bash
# Start PostgreSQL
docker run --name permit-postgres \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=permit_management_dev \
  -p 5432:5432 -d postgres:13

# Or use local PostgreSQL
createdb permit_management_dev
```

## 📁 Build Outputs

### Server Build
```
server/build/
├── libs/
│   └── server-all.jar          # Executable JAR
├── classes/                    # Compiled classes
└── resources/                  # Application resources
```

### Shared Module Build
```
shared/build/
├── libs/
│   └── shared.jar              # Shared library
├── classes/                    # Compiled classes
└── generated/                  # Generated code (SQLDelight)
```

### Full Multi-Platform Build
```
composeApp/build/
├── outputs/
│   └── apk/                    # Android APKs
├── libs/                       # Desktop JARs
└── bin/                        # iOS frameworks
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Android SDK Not Found
```
Error: SDK location not found
```

**Solution**:
```bash
# Use minimal setup
./setup-minimal-android.sh

# Or install full Android SDK
# Set ANDROID_HOME environment variable
```

#### 2. iOS Targets Disabled
```
Warning: Disabled Kotlin/Native Targets
```

**Solution**:
```bash
# This is normal on non-macOS systems
# Add to gradle.properties:
kotlin.native.ignoreDisabledTargets=true
```

#### 3. Test Task Issues
```
Error: Could not create task ':server:test'
```

**Solution**:
```bash
# Build without tests
./gradlew :server:compileKotlin

# Or fix test dependencies
./gradlew :server:test --stacktrace
```

#### 4. Memory Issues
```
Error: OutOfMemoryError
```

**Solution**:
```bash
# Increase memory in gradle.properties
org.gradle.jvmargs=-Xmx4096M -Dfile.encoding=UTF-8
```

### Build Commands Reference

#### Server Development
```bash
# Compile server
./gradlew :server:compileKotlin

# Run server
./gradlew :server:run

# Create JAR
./gradlew :server:shadowJar

# Run tests
./gradlew :server:test
```

#### Shared Module
```bash
# Compile JVM target
./gradlew :shared:compileKotlinJvm

# Compile all targets
./gradlew :shared:build

# Run tests
./gradlew :shared:test
```

#### Full Build
```bash
# Build everything
./gradlew build

# Clean build
./gradlew clean build

# Build with tests
./gradlew build test
```

## 🎯 Development Workflow

### 1. Backend Development
```bash
# Start development server
./gradlew :server:run

# In another terminal, test API
curl http://localhost:8080/health
curl http://localhost:8080/counties
```

### 2. Frontend Development
```bash
# Enable composeApp module
# Edit settings.gradle.kts: uncomment include(":composeApp")

# Build and run desktop app
./gradlew :composeApp:runDesktop

# Build Android app
./gradlew :composeApp:assembleDebug
```

### 3. Testing
```bash
# Run all tests
./gradlew test

# Run specific module tests
./gradlew :server:test
./gradlew :shared:test

# Run with coverage
./gradlew :server:jacocoTestReport
```

## 📦 Deployment

### Server Deployment
```bash
# Build production JAR
./gradlew :server:shadowJar

# Run production server
java -jar server/build/libs/server-all.jar
```

### Docker Deployment
```bash
# Build Docker image
docker build -f extra/deployment/Dockerfile.production -t permit-management:latest .

# Run with Docker Compose
docker-compose -f extra/deployment/docker-compose.production.yml up -d
```

## 🔄 Continuous Integration

### GitHub Actions Example
```yaml
name: Build

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up JDK 21
      uses: actions/setup-java@v3
      with:
        java-version: '21'
        distribution: 'temurin'
    
    - name: Build server
      run: ./gradlew :server:compileKotlin :shared:compileKotlinJvm
    
    - name: Create JAR
      run: ./gradlew :server:shadowJar
    
    - name: Run tests
      run: ./gradlew :server:test
```

## 📚 Additional Resources

- [Development Guide](docs/development/README.md) - Detailed development setup
- [Deployment Guide](docs/deployment/README.md) - Production deployment
- [API Documentation](docs/api/README.md) - API reference
- [Testing Guide](docs/testing/README.md) - Testing strategies

## 🆘 Getting Help

### Build Issues
1. Check this guide first
2. Review error messages carefully
3. Check prerequisites
4. Try clean build: `./gradlew clean build`

### Support
- GitHub Issues: Report build problems
- Documentation: Check docs/ directory
- Community: Ask questions in discussions

---

**Last Updated**: January 2025  
**Build Guide Version**: 1.0.0  
**Status**: Active Maintenance
