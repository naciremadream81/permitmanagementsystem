# 🗄️ Database Setup Guide

This guide will help you set up and configure PostgreSQL for your Permit Management System.

## Quick Start

### 1. **Automated Setup (Recommended)**
```bash
# Install and configure everything
./setup-database.sh production install

# Or for development
./setup-database.sh development install
```

### 2. **Manual Setup**
If you prefer to set up manually or the automated script doesn't work for your system:

```bash
# Install PostgreSQL (varies by OS)
# Ubuntu/Debian:
sudo apt-get install postgresql postgresql-contrib

# macOS:
brew install postgresql

# CentOS/RHEL:
sudo yum install postgresql-server postgresql-contrib
```

## Script Usage

### Main Setup Script: `./setup-database.sh`

```bash
# Full installation (recommended)
./setup-database.sh production install

# Just create database (if PostgreSQL already installed)
./setup-database.sh production create

# Test connection
./setup-database.sh production test

# Create backup
./setup-database.sh production backup

# Reset database (WARNING: deletes all data)
./setup-database.sh production reset
```

### Maintenance Script: `./db-maintenance.sh`

```bash
# Create backup
./db-maintenance.sh backup

# Check database health
./db-maintenance.sh health
```

## What the Setup Script Does

### 1. **Detects Your Operating System**
- Ubuntu/Debian
- CentOS/RHEL/Fedora
- macOS
- Generic Linux

### 2. **Installs PostgreSQL**
- Uses appropriate package manager
- Starts and enables the service
- Configures for production use

### 3. **Creates Secure Database**
- Creates dedicated database user
- Generates secure password
- Sets up proper permissions
- Creates application database

### 4. **Optimizes for Production**
- Connection pooling settings
- Memory optimization
- Logging configuration
- Security hardening

### 5. **Creates Environment File**
- Database connection details
- Secure JWT secret
- Server configuration
- All necessary environment variables

## Environment Files Created

After running the setup, you'll have:

```bash
.env.production     # Production environment
.env.staging        # Staging environment  
.env.development    # Development environment
```

Example `.env.production`:
```bash
DATABASE_URL=jdbc:postgresql://localhost:5432/permit_management_prod
DB_USER=permit_user
DB_PASSWORD=secure-generated-password
JWT_SECRET=secure-32-character-secret
ENVIRONMENT=production
```

## Database Configuration

### Production Settings Applied
- **Connection pooling**: Optimized for concurrent users
- **Memory settings**: Tuned for performance
- **Logging**: Comprehensive logging for monitoring
- **Security**: SSL enabled, secure authentication

### Database Structure
The application will automatically create these tables:
- `users` - User accounts and authentication
- `counties` - County information
- `checklist_items` - County-specific requirements
- `permit_packages` - Permit applications
- `permit_documents` - Uploaded files

## Security Features

### 1. **Dedicated Database User**
- Not using postgres superuser
- Minimal required permissions
- Secure password generation

### 2. **Network Security**
- Local connections only by default
- SSL/TLS encryption enabled
- Secure authentication methods

### 3. **Data Protection**
- Regular backup capabilities
- Transaction logging
- Connection monitoring

## Monitoring and Maintenance

### Database Monitoring
```bash
# Run the generated monitoring script
./monitor-database.sh

# Check database health
./db-maintenance.sh health
```

### Backup and Recovery
```bash
# Create backup
./db-maintenance.sh backup

# Backups are stored in: backups/
# Format: permit_management_prod_YYYYMMDD_HHMMSS.sql.gz
```

### Performance Monitoring
The monitoring script shows:
- Connection status
- Database size
- Active connections
- Table statistics
- Recent activity

## Troubleshooting

### Common Issues

#### 1. **PostgreSQL Not Starting**
```bash
# Check status
sudo systemctl status postgresql

# Start manually
sudo systemctl start postgresql

# Check logs
sudo journalctl -u postgresql
```

#### 2. **Connection Failed**
```bash
# Test connection manually
psql -h localhost -U permit_user -d permit_management_prod

# Check if PostgreSQL is listening
netstat -tlnp | grep 5432
```

#### 3. **Permission Denied**
```bash
# Check PostgreSQL is running as correct user
ps aux | grep postgres

# Check file permissions
ls -la /var/lib/postgresql/
```

#### 4. **Database Already Exists**
```bash
# Reset database (WARNING: deletes data)
./setup-database.sh production reset

# Or manually drop
sudo -u postgres psql -c "DROP DATABASE permit_management_prod;"
```

### Log Locations
- **PostgreSQL logs**: `/var/log/postgresql/` (Linux) or `/usr/local/var/log/` (macOS)
- **Application logs**: `logs/server.log`
- **Setup logs**: Console output during setup

## Advanced Configuration

### Custom Database Settings
Edit the generated `.env.production` file:

```bash
# Database connection
DATABASE_URL=jdbc:postgresql://your-host:5432/your-db
DB_USER=your-user
DB_PASSWORD=your-password

# Connection pooling
DB_POOL_SIZE=20
DB_CONNECTION_TIMEOUT=60000
```

### Remote Database
To use a remote PostgreSQL server:

1. Update the environment file:
```bash
DATABASE_URL=jdbc:postgresql://remote-host:5432/permit_management_prod
DB_HOST=remote-host
```

2. Ensure firewall allows connections
3. Configure PostgreSQL to accept remote connections

### SSL Configuration
For production with SSL:

```bash
# In postgresql.conf
ssl = on
ssl_cert_file = 'server.crt'
ssl_key_file = 'server.key'
```

## Production Checklist

Before going live:

- [ ] Database setup completed successfully
- [ ] Connection test passes
- [ ] Environment variables configured
- [ ] Backup system tested
- [ ] Monitoring script working
- [ ] SSL configured (if required)
- [ ] Firewall rules configured
- [ ] Performance testing completed

## Support

### Getting Help
1. Check the logs first
2. Run the health check: `./db-maintenance.sh health`
3. Verify environment variables are set
4. Test database connection manually

### Useful Commands
```bash
# Check PostgreSQL version
psql --version

# List databases
sudo -u postgres psql -l

# Connect to database
psql -h localhost -U permit_user -d permit_management_prod

# Show database size
SELECT pg_size_pretty(pg_database_size('permit_management_prod'));

# Show active connections
SELECT * FROM pg_stat_activity WHERE datname = 'permit_management_prod';
```

---

## 🚀 Ready to Deploy!

Once database setup is complete:

1. **Source the environment**:
   ```bash
   source .env.production
   ```

2. **Start the application**:
   ```bash
   ./deploy-server.sh production
   ```

3. **Verify everything works**:
   ```bash
   curl http://localhost:8080/health/db
   ```

Your database is now ready for production use! 🎉
