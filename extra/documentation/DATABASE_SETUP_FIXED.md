# 🗄️ Fixed Database Setup Scripts

The original database setup script had issues with macOS and Linux systems. Here are the fixed versions:

## 🚀 Quick Start (Recommended)

Use the universal script that automatically detects your OS:

```bash
# For development
./setup-database-universal.sh development install

# For production
./setup-database-universal.sh production install
```

## 📋 Available Scripts

### 1. **Universal Script** (Recommended)
- **File**: `setup-database-universal.sh`
- **Purpose**: Automatically detects your OS and runs the appropriate script
- **Usage**: `./setup-database-universal.sh [environment] [action]`

### 2. **macOS Specific Script**
- **File**: `setup-database-macos.sh`
- **Purpose**: Optimized for macOS with Homebrew
- **Fixes**: 
  - No `postgres` system user required
  - Correct PostgreSQL paths for Homebrew
  - Uses current user for database operations

### 3. **Linux Specific Script**
- **File**: `setup-database-linux.sh`
- **Purpose**: Works with Debian/Ubuntu/Kali Linux
- **Fixes**:
  - Proper `sudo -u postgres` usage
  - Correct systemctl commands
  - Distribution detection
  - Security configuration

## 🔧 What Was Fixed

### Original Issues:
1. **macOS**: Script tried to use `sudo -u postgres` but macOS doesn't have a `postgres` system user
2. **Linux**: Script had incorrect paths and missing security configurations
3. **Both**: Generic script didn't handle OS-specific differences

### Solutions Applied:
1. **macOS**: Connect directly as current user (who has superuser privileges)
2. **Linux**: Properly use `sudo -u postgres` and configure pg_hba.conf
3. **Universal**: Auto-detect OS and run appropriate script

## 📖 Usage Examples

### Basic Setup
```bash
# Development environment (default)
./setup-database-universal.sh

# Production environment
./setup-database-universal.sh production install
```

### Testing and Maintenance
```bash
# Test database connection
./setup-database-universal.sh development test

# Create backup
./setup-database-universal.sh production backup

# Check PostgreSQL installation
./setup-database-universal.sh development check
```

### Reset Database (⚠️ Destructive)
```bash
# Reset development database
./setup-database-universal.sh development reset
```

## 🎯 What Each Script Does

### Installation Process:
1. **Detects your operating system**
2. **Installs PostgreSQL** (if not already installed)
3. **Starts PostgreSQL service**
4. **Creates secure database user** with generated password
5. **Creates application database**
6. **Sets up proper permissions**
7. **Configures security settings** (Linux only)
8. **Tests database connection**
9. **Creates environment file** with all settings

### Generated Files:
- `.env.development` - Development environment variables
- `.env.staging` - Staging environment variables  
- `.env.production` - Production environment variables

## 🔐 Security Features

### macOS:
- Secure password generation
- Proper user permissions
- Environment file protection (600 permissions)

### Linux:
- All macOS features plus:
- pg_hba.conf configuration
- Service security settings
- Connection restrictions

## 🐛 Troubleshooting

### If the script fails:

1. **Check PostgreSQL installation**:
   ```bash
   ./setup-database-universal.sh development check
   ```

2. **Manual PostgreSQL installation**:
   ```bash
   # macOS
   brew install postgresql@14
   brew services start postgresql@14
   
   # Linux (Debian/Ubuntu/Kali)
   sudo apt-get update
   sudo apt-get install postgresql postgresql-contrib
   sudo systemctl start postgresql
   ```

3. **Test connection manually**:
   ```bash
   # Source the environment file first
   source .env.development
   
   # Test connection
   PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT version();"
   ```

### Common Issues:

#### macOS:
- **Homebrew not found**: Install Homebrew first
- **PostgreSQL not starting**: Try `brew services restart postgresql@14`

#### Linux:
- **Permission denied**: Make sure you have sudo privileges
- **Service not starting**: Check `sudo systemctl status postgresql`
- **Connection refused**: Ensure PostgreSQL is listening on port 5432

## 🚀 Next Steps

After successful database setup:

1. **Review environment file**:
   ```bash
   cat .env.development
   ```

2. **Source the environment**:
   ```bash
   source .env.development
   ```

3. **Start the application**:
   ```bash
   ./gradlew :server:run
   ```

4. **Test the API**:
   ```bash
   curl http://localhost:8080/
   ```

## 📊 Environment File Contents

The generated `.env.development` file contains:

```bash
# Database Configuration
DATABASE_URL=jdbc:postgresql://localhost:5432/permit_management_dev
DB_USER=permit_user_dev
DB_PASSWORD=<generated-secure-password>
DB_HOST=localhost
DB_PORT=5432
DB_NAME=permit_management_dev

# Server Configuration
SERVER_PORT=8080
SERVER_HOST=0.0.0.0
ENVIRONMENT=development

# Security
JWT_SECRET=<generated-32-character-secret>

# File Upload
UPLOAD_MAX_SIZE=10485760
UPLOAD_DIR=./uploads

# Logging
LOG_LEVEL=INFO
LOG_FILE=./logs/server.log
```

## ✅ Success Indicators

You'll know the setup worked when you see:
- ✅ Database connection test successful
- ✅ Environment file created
- ✅ Database is ready for use! 🚀

The database is now ready for your Permit Management System! 🎉
