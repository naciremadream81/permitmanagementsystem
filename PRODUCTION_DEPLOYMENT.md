# 🚀 Production Deployment Guide

## Quick Start

### 1. **Deploy Server**
```bash
# Set environment variables
export DB_PASSWORD="your-secure-password"
export JWT_SECRET="your-secure-jwt-secret-key"

# Deploy server
./deploy-server.sh production
```

### 2. **Install Desktop Apps**
```bash
# Install on any desktop (macOS, Linux, Windows)
./install-desktop.sh
```

## 📋 Prerequisites

### Server Requirements
- **OS**: Linux, macOS, or Windows Server
- **Java**: OpenJDK 17 or higher
- **Database**: PostgreSQL 12+ (or use Docker)
- **Memory**: 2GB RAM minimum, 4GB recommended
- **Storage**: 10GB minimum for logs and uploads
- **Network**: Port 8080 accessible (or configure custom port)

### Desktop Requirements
- **OS**: macOS 10.14+, Linux (Ubuntu 18.04+), Windows 10+
- **Java**: OpenJDK 11 or higher
- **Memory**: 1GB RAM minimum
- **Storage**: 500MB for application and local database

## 🔧 Server Deployment Options

### Option 1: Direct Deployment (Recommended for development/staging)

1. **Configure Environment**
   ```bash
   cp .env.production .env
   # Edit .env with your production values
   ```

2. **Deploy Server**
   ```bash
   ./deploy-server.sh production
   ```

3. **Verify Deployment**
   ```bash
   curl http://localhost:8080/
   # Should return: "Permit Management System API is running"
   ```

### Option 2: Docker Deployment (Recommended for production)

1. **Configure Environment**
   ```bash
   cp .env.production .env
   # Edit .env with your production values
   ```

2. **Deploy with Docker**
   ```bash
   docker-compose -f docker-compose.prod.yml up -d
   ```

3. **Verify Deployment**
   ```bash
   docker-compose -f docker-compose.prod.yml ps
   curl http://localhost:8080/
   ```

### Option 3: Cloud Deployment

#### AWS Deployment
```bash
# Using AWS ECS or EC2
# 1. Build Docker image
docker build -f Dockerfile.server -t permit-management-server .

# 2. Push to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com
docker tag permit-management-server:latest <account>.dkr.ecr.us-east-1.amazonaws.com/permit-management-server:latest
docker push <account>.dkr.ecr.us-east-1.amazonaws.com/permit-management-server:latest

# 3. Deploy to ECS or EC2
```

#### Google Cloud Deployment
```bash
# Using Google Cloud Run
gcloud builds submit --tag gcr.io/PROJECT-ID/permit-management-server
gcloud run deploy --image gcr.io/PROJECT-ID/permit-management-server --platform managed
```

## 🖥️ Desktop App Deployment

### Mass Installation Script

For deploying to multiple desktops, create a deployment package:

```bash
# Create deployment package
./create-deployment-package.sh

# This creates: permit-management-desktop-v1.0.0.zip
# Contains:
# - Pre-built application
# - Installation script
# - Configuration files
# - User guide
```

### Enterprise Deployment

#### Windows (Group Policy)
1. Build MSI installer: `./build-msi-installer.sh`
2. Deploy via Group Policy or SCCM
3. Configure via registry or config files

#### macOS (MDM)
1. Build PKG installer: `./build-pkg-installer.sh`
2. Deploy via Jamf, Intune, or other MDM
3. Configure via plist files

#### Linux (Package Manager)
1. Build DEB/RPM packages: `./build-linux-packages.sh`
2. Deploy via apt/yum repositories
3. Configure via /etc/permit-management/

## 🔒 Security Configuration

### SSL/TLS Setup

1. **Obtain SSL Certificate**
   ```bash
   # Using Let's Encrypt
   certbot certonly --standalone -d yourdomain.com
   ```

2. **Configure Nginx (if using)**
   ```nginx
   server {
       listen 443 ssl;
       server_name yourdomain.com;
       
       ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
       
       location / {
           proxy_pass http://localhost:8080;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }
   }
   ```

### Database Security

1. **Create Database User**
   ```sql
   CREATE USER permit_user WITH PASSWORD 'secure-password';
   CREATE DATABASE permit_management_prod OWNER permit_user;
   GRANT ALL PRIVILEGES ON DATABASE permit_management_prod TO permit_user;
   ```

2. **Configure PostgreSQL**
   ```bash
   # Edit postgresql.conf
   listen_addresses = 'localhost'
   ssl = on
   
   # Edit pg_hba.conf
   local   permit_management_prod   permit_user   md5
   host    permit_management_prod   permit_user   127.0.0.1/32   md5
   ```

### Firewall Configuration

```bash
# Ubuntu/Debian
sudo ufw allow 8080/tcp
sudo ufw allow 5432/tcp  # Only if database is remote

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

## 📊 Monitoring & Maintenance

### Log Management

```bash
# View server logs
tail -f logs/server.log

# Rotate logs (automatic with logrotate)
sudo logrotate -f logrotate.conf
```

### Health Monitoring

```bash
# Check server health
curl http://localhost:8080/health

# Check database connection
curl http://localhost:8080/health/db

# Monitor with systemd (Linux)
sudo systemctl status permit-management
```

### Backup Strategy

```bash
# Database backup
pg_dump permit_management_prod > backup_$(date +%Y%m%d).sql

# Application backup
tar -czf app_backup_$(date +%Y%m%d).tar.gz uploads/ logs/ data/

# Automated backup (add to crontab)
0 2 * * * /path/to/backup-script.sh
```

## 🔄 Updates & Maintenance

### Server Updates

```bash
# Stop server
./stop-server.sh

# Backup current version
cp -r . ../permit-management-backup-$(date +%Y%m%d)

# Update code
git pull origin main

# Deploy new version
./deploy-server.sh production
```

### Desktop App Updates

```bash
# Build new version
./install-desktop.sh

# For mass deployment, create update package
./create-update-package.sh
```

## 🚨 Troubleshooting

### Common Issues

#### Server Won't Start
```bash
# Check logs
tail -f logs/server.log

# Check port availability
netstat -tlnp | grep 8080

# Check database connection
psql -h localhost -U permit_user -d permit_management_prod
```

#### Desktop App Won't Connect
1. Check server URL in app settings
2. Verify server is running: `curl http://server:8080/`
3. Check firewall settings
4. Verify network connectivity

#### Database Issues
```bash
# Check database status
sudo systemctl status postgresql

# Check connections
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity;"

# Reset database (if needed)
sudo -u postgres dropdb permit_management_prod
sudo -u postgres createdb permit_management_prod -O permit_user
```

## 📞 Support

### Log Collection
```bash
# Collect all logs for support
./collect-support-logs.sh
# Creates: support-logs-$(date +%Y%m%d).tar.gz
```

### Performance Monitoring
```bash
# Monitor server performance
htop
iostat -x 1
netstat -i

# Monitor database performance
sudo -u postgres psql -c "SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;"
```

## 🎉 Production Checklist

### Pre-Deployment
- [ ] Environment variables configured
- [ ] Database created and secured
- [ ] SSL certificates obtained (if using HTTPS)
- [ ] Firewall rules configured
- [ ] Backup strategy implemented
- [ ] Monitoring setup

### Post-Deployment
- [ ] Server health check passes
- [ ] Desktop apps can connect
- [ ] User authentication works
- [ ] File uploads work
- [ ] Offline functionality tested
- [ ] Sync functionality tested
- [ ] Backup process tested

### Go-Live
- [ ] DNS configured (if using domain)
- [ ] Load balancer configured (if using)
- [ ] Monitoring alerts configured
- [ ] Support documentation updated
- [ ] Users trained
- [ ] Rollback plan ready

## 🚀 Your Production System is Ready!

With these scripts and configurations, you have a complete production deployment system for your offline-first permit management application. The system is designed to be:

- **Scalable**: Can handle multiple users and large datasets
- **Reliable**: Includes health checks, logging, and error recovery
- **Secure**: Implements authentication, authorization, and data protection
- **Maintainable**: Includes monitoring, backup, and update procedures
- **User-Friendly**: Simple installation and configuration for end users

**Ready for production deployment! 🎉**
