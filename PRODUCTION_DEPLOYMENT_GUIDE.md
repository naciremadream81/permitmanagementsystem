# Production Deployment Guide

This guide covers deploying the Permit Management System to production using Docker.

## 🚀 Quick Start

1. **Configure Environment**
   ```bash
   cp .env.prod .env.prod.local
   # Edit .env.prod.local with your production values
   ```

2. **Deploy**
   ```bash
   ./deploy-production.sh
   ```

3. **Monitor**
   ```bash
   ./monitor-production.sh
   ```

## 📋 Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- 2GB+ RAM
- 10GB+ disk space
- SSL certificates (for HTTPS)

## 🔧 Configuration

### Environment Variables

Copy `.env.prod` to `.env.prod.local` and configure:

```bash
# Database
POSTGRES_DB=permit_management_prod
POSTGRES_USER=permit_user
POSTGRES_PASSWORD=your-secure-password-here

# JWT (must be 32+ characters)
JWT_SECRET=your-super-secure-jwt-secret-key-here

# Domain
DOMAIN=yourdomain.com
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://app.yourdomain.com
```

### SSL Certificates

Place your SSL certificates in `nginx/ssl/`:
- `cert.pem` - SSL certificate
- `key.pem` - Private key

Or use Let's Encrypt:
```bash
# Install certbot
sudo apt install certbot

# Get certificates
sudo certbot certonly --standalone -d yourdomain.com

# Copy to nginx directory
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem nginx/ssl/key.pem
```

## 🏗️ Architecture

```
Internet → Nginx (443/80) → Server (8080) → PostgreSQL (5432)
                         → Redis (6379)
```

### Services

- **nginx**: Reverse proxy, SSL termination, static files
- **server**: Kotlin/Ktor API server
- **postgres**: PostgreSQL database
- **redis**: Caching and sessions (optional)

## 📦 Deployment Options

### Option 1: Single Server (Recommended for small-medium apps)

```bash
# Use the provided docker-compose.prod.yml
./deploy-production.sh
```

### Option 2: Cloud Platforms

#### AWS ECS
```bash
# Build and push to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

docker build -f Dockerfile.production -t permit-management .
docker tag permit-management:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/permit-management:latest
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/permit-management:latest

# Deploy using ECS task definition
```

#### Google Cloud Run
```bash
# Build and deploy
gcloud builds submit --tag gcr.io/PROJECT-ID/permit-management
gcloud run deploy --image gcr.io/PROJECT-ID/permit-management --platform managed
```

#### DigitalOcean App Platform
```yaml
# app.yaml
name: permit-management
services:
- name: api
  source_dir: /
  dockerfile_path: Dockerfile.production
  instance_count: 1
  instance_size_slug: basic-xxs
  http_port: 8080
  environment_slug: node-js
  envs:
  - key: DATABASE_URL
    value: ${db.DATABASE_URL}
  - key: JWT_SECRET
    value: ${JWT_SECRET}
databases:
- name: db
  engine: PG
  version: "13"
```

### Option 3: Kubernetes

```yaml
# k8s-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: permit-management
spec:
  replicas: 3
  selector:
    matchLabels:
      app: permit-management
  template:
    metadata:
      labels:
        app: permit-management
    spec:
      containers:
      - name: server
        image: permit-management:latest
        ports:
        - containerPort: 8080
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: permit-secrets
              key: database-url
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: permit-secrets
              key: jwt-secret
```

## 🔒 Security Checklist

- [ ] Strong database password (16+ characters)
- [ ] Secure JWT secret (32+ characters)
- [ ] SSL certificates installed
- [ ] Firewall configured (only 80, 443, 22 open)
- [ ] Regular security updates
- [ ] Database backups enabled
- [ ] Log monitoring configured
- [ ] Rate limiting enabled
- [ ] CORS properly configured

## 📊 Monitoring & Maintenance

### Health Checks

The system includes built-in health checks:
- Database connectivity
- API responsiveness
- Nginx proxy status

### Monitoring Script

```bash
./monitor-production.sh
```

Shows:
- Container status
- Resource usage
- Recent errors
- Database statistics
- Backup status

### Logs

```bash
# View all logs
docker-compose -f docker-compose.prod.yml logs

# View specific service
docker-compose -f docker-compose.prod.yml logs server

# Follow logs
docker-compose -f docker-compose.prod.yml logs -f server
```

### Backups

```bash
# Manual backup
./backup-production.sh

# Automated backups (add to crontab)
0 2 * * * /path/to/backup-production.sh
```

## 🔄 Updates & Rollbacks

### Update Application

```bash
# Pull latest code
git pull origin main

# Rebuild and deploy
./deploy-production.sh
```

### Rollback

```bash
# Stop current version
docker-compose -f docker-compose.prod.yml down

# Restore from backup
gunzip -c backups/database_YYYYMMDD_HHMMSS.sql.gz | \
  docker-compose -f docker-compose.prod.yml exec -T postgres \
  psql -U permit_user -d permit_management_prod

# Start previous version
git checkout PREVIOUS_COMMIT
./deploy-production.sh
```

## 🚨 Troubleshooting

### Common Issues

1. **Container won't start**
   ```bash
   docker-compose -f docker-compose.prod.yml logs server
   ```

2. **Database connection failed**
   ```bash
   # Check database logs
   docker-compose -f docker-compose.prod.yml logs postgres
   
   # Test connection
   docker-compose -f docker-compose.prod.yml exec postgres \
     psql -U permit_user -d permit_management_prod -c "SELECT 1;"
   ```

3. **SSL certificate issues**
   ```bash
   # Check certificate validity
   openssl x509 -in nginx/ssl/cert.pem -text -noout
   
   # Test SSL
   curl -I https://yourdomain.com
   ```

4. **High memory usage**
   ```bash
   # Check container stats
   docker stats
   
   # Adjust JVM settings in Dockerfile.production
   ENV JAVA_OPTS="-Xmx512m -Xms256m"
   ```

### Performance Tuning

1. **Database**
   ```sql
   -- Add indexes for better performance
   CREATE INDEX idx_permit_packages_user_id ON permit_packages(user_id);
   CREATE INDEX idx_permit_documents_package_id ON permit_documents(package_id);
   ```

2. **Application**
   ```bash
   # Scale server instances
   docker-compose -f docker-compose.prod.yml up -d --scale server=3
   ```

3. **Nginx**
   ```nginx
   # Enable caching in nginx.conf
   location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
       expires 1y;
       add_header Cache-Control "public, immutable";
   }
   ```

## 📈 Scaling

### Horizontal Scaling

```bash
# Scale server instances
docker-compose -f docker-compose.prod.yml up -d --scale server=3

# Use load balancer
# Update nginx upstream configuration
```

### Vertical Scaling

```yaml
# In docker-compose.prod.yml
services:
  server:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G
```

## 🔐 Production Security

### Firewall Configuration

```bash
# Ubuntu/Debian
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# CentOS/RHEL
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### Regular Updates

```bash
# System updates
sudo apt update && sudo apt upgrade -y

# Docker updates
sudo apt update docker-ce docker-ce-cli containerd.io

# Application updates
git pull origin main
./deploy-production.sh
```

## 📞 Support

For issues:
1. Check logs: `./monitor-production.sh`
2. Review troubleshooting section
3. Check GitHub issues
4. Contact support team

## 📚 Additional Resources

- [Docker Production Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Nginx Security Guide](https://nginx.org/en/docs/http/securing_http.html)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)
- [Let's Encrypt SSL Setup](https://letsencrypt.org/getting-started/)
