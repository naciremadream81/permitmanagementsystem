# 📁 Project Organization Guide

## Overview

This document provides a comprehensive guide to the organized file structure of the Permit Management System. All files have been systematically organized for better maintainability and clarity.

## 🏗️ Directory Structure

```
permitmanagementsystem/
├── 📁 Core Application
│   ├── server/                     # Backend server (Ktor)
│   ├── shared/                     # Shared business logic (KMP)
│   ├── composeApp/                 # Mobile & Desktop apps (Compose)
│   └── iosApp/                     # iOS-specific code
│
├── 📁 Documentation
│   ├── docs/                       # Main documentation
│   │   ├── api/                    # API documentation
│   │   ├── deployment/             # Deployment guides
│   │   ├── development/            # Development guides
│   │   ├── monitoring/             # Monitoring guides
│   │   └── testing/                # Testing guides
│   ├── README.md                   # Main project README
│   ├── IMPLEMENTATION_SUMMARY.md   # Recent enhancements
│   └── PROJECT_ORGANIZATION.md     # This file
│
├── 📁 Extra Resources
│   ├── extra/
│   │   ├── documentation/          # Historical documentation
│   │   ├── scripts/                # Utility scripts
│   │   ├── web-apps/               # Web application files
│   │   ├── deployment/             # Docker and deployment configs
│   │   ├── testing/                # Test scripts
│   │   ├── logs/                   # Log files
│   │   └── backups/                # Backup files
│   └── nginx/                      # Nginx configuration
│
├── 📁 Build & Configuration
│   ├── build.gradle.kts            # Root build configuration
│   ├── settings.gradle.kts         # Project settings
│   ├── gradle/                     # Gradle wrapper and configuration
│   ├── gradlew                     # Gradle wrapper script
│   └── gradlew.bat                 # Gradle wrapper script (Windows)
│
├── 📁 Runtime & Data
│   ├── uploads/                    # File uploads directory
│   ├── logs/                       # Application logs
│   ├── backups/                    # Database backups
│   └── dist/                       # Distribution files
│
└── 📁 Infrastructure
    ├── docker-compose.yml          # Docker Compose configuration
    └── .git/                       # Git repository
```

## 📋 File Categories

### 🎯 Core Application Files

#### Server Module (`server/`)
- **Purpose**: Backend API server built with Ktor
- **Key Files**:
  - `Application.kt` - Main application entry point
  - `models/` - Data models and DTOs
  - `routes/` - API route handlers
  - `services/` - Business logic
  - `config/` - Configuration classes
  - `database/` - Database models and setup
  - `error/` - Error handling
  - `health/` - Health check endpoints
  - `logging/` - Logging utilities

#### Shared Module (`shared/`)
- **Purpose**: Shared business logic across platforms
- **Key Files**:
  - `models/` - Shared data models
  - `api/` - API client interfaces
  - `database/` - Database interfaces

#### Compose App (`composeApp/`)
- **Purpose**: Mobile and desktop applications
- **Key Files**:
  - `commonMain/` - Shared UI code
  - `androidMain/` - Android-specific code
  - `iosMain/` - iOS-specific code
  - `desktopMain/` - Desktop-specific code

#### iOS App (`iosApp/`)
- **Purpose**: iOS-specific implementation
- **Key Files**:
  - `iosApp/` - iOS app code
  - `iosApp.xcodeproj/` - Xcode project

### 📚 Documentation Files

#### Main Documentation (`docs/`)
- **`api/README.md`** - Complete API reference
- **`deployment/README.md`** - Production deployment guide
- **`development/README.md`** - Development setup and standards
- **`monitoring/README.md`** - Monitoring and observability
- **`testing/README.md`** - Testing strategies and practices

#### Project Documentation
- **`README.md`** - Main project overview and quick start
- **`IMPLEMENTATION_SUMMARY.md`** - Recent enhancements and features
- **`PROJECT_ORGANIZATION.md`** - This organization guide

### 🗂️ Extra Resources (`extra/`)

#### Historical Documentation (`extra/documentation/`)
- **Purpose**: Preserve development history and legacy documentation
- **Contents**: 37+ markdown files documenting the development journey
- **Note**: These are historical records, not current documentation

#### Utility Scripts (`extra/scripts/`)
- **Purpose**: Automation and utility scripts
- **Key Scripts**:
  - `setup-*.sh` - Environment setup scripts
  - `deploy-*.sh` - Deployment scripts
  - `monitor-*.sh` - Monitoring scripts
  - `backup-*.sh` - Backup scripts
  - `test-*.sh` - Testing scripts

#### Web Applications (`extra/web-apps/`)
- **Purpose**: Web interface examples and prototypes
- **Key Files**:
  - `web-app.html` - Main web application
  - `web-app-production.html` - Production version
  - `web-app-admin.html` - Admin interface
  - `web-app-js-functions.js` - JavaScript functions

#### Deployment Configurations (`extra/deployment/`)
- **Purpose**: Docker and deployment configurations
- **Key Files**:
  - `docker-compose*.yml` - Various Docker Compose configurations
  - `Dockerfile*` - Docker build files
  - `nginx.conf` - Nginx configuration

#### Testing Utilities (`extra/testing/`)
- **Purpose**: Test scripts and utilities
- **Key Files**:
  - `test-*.sh` - Various test scripts
  - `validate-*.sh` - Validation scripts
  - `verify-*.sh` - Verification scripts

#### Log Files (`extra/logs/`)
- **Purpose**: Historical log files
- **Contents**: Server logs from development and testing

#### Backup Files (`extra/backups/`)
- **Purpose**: Backup files and configurations
- **Contents**: Database backups, configuration files, and other backups

### ⚙️ Configuration Files

#### Build Configuration
- **`build.gradle.kts`** - Root build configuration
- **`settings.gradle.kts`** - Project settings and module configuration
- **`gradle/`** - Gradle wrapper and version catalogs

#### Runtime Configuration
- **`nginx/`** - Nginx configuration files
- **`docker-compose.yml`** - Docker Compose configuration
- **`uploads/`** - File upload directory
- **`logs/`** - Application logs directory

## 🎯 File Organization Principles

### 1. **Separation of Concerns**
- Core application code in dedicated modules
- Documentation in organized structure
- Extra resources separated from core functionality
- Configuration files grouped logically

### 2. **Accessibility**
- Main documentation easily accessible
- Historical information preserved but separated
- Scripts organized by purpose
- Clear naming conventions

### 3. **Maintainability**
- Logical directory structure
- Consistent file naming
- Clear separation between active and historical files
- Easy navigation and discovery

### 4. **Scalability**
- Modular structure supports growth
- Clear boundaries between components
- Extensible documentation structure
- Organized resource management

## 📖 How to Navigate

### For New Developers
1. Start with `README.md` for project overview
2. Read `docs/development/README.md` for setup
3. Check `docs/api/README.md` for API reference
4. Review `docs/testing/README.md` for testing

### For DevOps Engineers
1. Check `docs/deployment/README.md` for deployment
2. Review `docs/monitoring/README.md` for monitoring
3. Use `extra/scripts/` for automation
4. Check `extra/deployment/` for Docker configs

### For API Users
1. Read `docs/api/README.md` for API reference
2. Check `extra/web-apps/` for examples
3. Review `docs/testing/README.md` for testing

### For Project Managers
1. Read `README.md` for project overview
2. Check `IMPLEMENTATION_SUMMARY.md` for recent work
3. Review `docs/` for comprehensive information
4. Use `extra/documentation/` for historical context

## 🔧 Maintenance Guidelines

### Adding New Files
1. **Core Application**: Add to appropriate module (`server/`, `shared/`, `composeApp/`)
2. **Documentation**: Add to `docs/` with appropriate categorization
3. **Scripts**: Add to `extra/scripts/` with descriptive naming
4. **Configuration**: Add to appropriate configuration directory

### File Naming Conventions
- **Documentation**: Use descriptive names with `.md` extension
- **Scripts**: Use `action-description.sh` format
- **Configuration**: Use descriptive names with appropriate extensions
- **Code**: Follow Kotlin naming conventions

### Directory Maintenance
- **Regular Cleanup**: Remove outdated files from `extra/`
- **Documentation Updates**: Keep `docs/` current with code changes
- **Log Rotation**: Manage log files in `logs/` directories
- **Backup Management**: Regular cleanup of old backups

## 📊 File Statistics

### Current Organization
- **Core Application**: 4 modules (server, shared, composeApp, iosApp)
- **Documentation**: 5 main guides + project documentation
- **Extra Resources**: 6 categories with 100+ files
- **Configuration**: Build, runtime, and deployment configs
- **Total Files**: 200+ organized files

### Benefits Achieved
- ✅ **Clear Structure**: Easy navigation and understanding
- ✅ **Separation of Concerns**: Core vs. extra resources
- ✅ **Historical Preservation**: Development history maintained
- ✅ **Accessibility**: Quick access to relevant information
- ✅ **Maintainability**: Easy to update and extend

## 🚀 Future Organization

### Planned Improvements
1. **Automated Organization**: Scripts to maintain file organization
2. **Documentation Generation**: Auto-generate docs from code
3. **Resource Management**: Better management of extra resources
4. **Search Integration**: Enhanced search across documentation

### Extension Points
1. **New Modules**: Easy addition of new application modules
2. **Documentation Categories**: Expandable documentation structure
3. **Script Organization**: Categorized script management
4. **Configuration Management**: Centralized configuration handling

---

## 📞 Support

For questions about project organization:
- Check this guide first
- Review the documentation in `docs/`
- Check `extra/documentation/` for historical context
- Contact the development team

**Last Updated**: January 2025  
**Organization Version**: 1.0.0  
**Status**: Active Maintenance
