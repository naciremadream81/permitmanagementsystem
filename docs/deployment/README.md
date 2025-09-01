# Deployment Guide

## Overview

This guide covers deploying the Permit Management System in various environments, from development to production.

## Prerequisites

- Java 21+
- PostgreSQL 13+
- Docker (optional)
- Nginx (production)
- SSL certificates (production)

## Environment Setup

### Development Environment

1. **Clone the repository**
```bash
git clone <repository-url>
cd permitmanagementsystem
```

2. **Set up environment variables**
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. **Start PostgreSQL**
```bash
# Using Docker
docker run --name permit-postgres \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=permit_management_dev \
  -p 5432:5432 -d postgres:13

# Or using local PostgreSQL
createdb permit_management_dev
```

4. **Run the application**
```bash
./gradlew :server:run
```

### Production Environment

#### Using Docker (Recommended)

1. **Build the production image**
```bash
docker build -f extra/deployment/Dockerfile.production -t permit-management:latest .
```

2. **Deploy with docker-compose**
```bash
docker-compose -f extra/deployment/docker-compose.production.yml up -d
```

#### Manual Deployment

1. **Build the application**
```bash
./gradlew :server:shadowJar
```

2. **Set up production database**
```bash
# Create production database
createdb permit_management_prod

# Run migrations
./gradlew :server:run --args="--migrate"
```

3. **Configure environment**
```bash
export DATABASE_URL=jdbc:postgresql://localhost:5432/permit_management_prod
export DB_USERNAME=permit_user
export DB_PASSWORD=secure_password
export JWT_SECRET=your-super-secure-jwt-secret-key
export ENVIRONMENT=production
export SERVER_PORT=8080
```

4. **Start the application**
```bash
java -jar server/build/libs/server-all.jar
```

## Docker Deployment

### Dockerfile Configuration

The production Dockerfile is optimized for:
- Multi-stage builds
- Minimal image size
- Security hardening
- Health checks

### Docker Compose

Use the provided docker-compose files for different environments:

- `docker-compose.yml` - Development
- `docker-compose.production.yml` - Production
- `docker-compose.full-prod.yml` - Full production with monitoring

### Environment Variables

```yaml
# docker-compose.production.yml
version: '3.8'
services:
  app:
    image: permit-management:latest
    environment:
      - DATABASE_URL=jdbc:postgresql://db:5432/permit_management_prod
      - DB_USERNAME=permit_user
      - DB_PASSWORD=${DB_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
      - ENVIRONMENT=production
    depends_on:
      - db
    ports:
      - "8080:8080"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  db:
    image: postgres:13
    environment:
      - POSTGRES_DB=permit_management_prod
      - POSTGRES_USER=permit_user
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

volumes:
  postgres_data:
```

## Nginx Configuration

### Basic Configuration

```nginx
# /etc/nginx/sites-available/permit-management
server {
    listen 80;
    server_name your-domain.com;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    # SSL Configuration
    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    
    # Security Headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
    
    # API Proxy
    location /api/ {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS Headers
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
        add_header Access-Control-Allow-Headers "Authorization, Content-Type";
    }
    
    # Static Files
    location / {
        root /var/www/permit-management;
        try_files $uri $uri/ /index.html;
    }
    
    # File Uploads
    location /uploads/ {
        alias /var/www/permit-management/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### SSL/TLS Setup

1. **Obtain SSL Certificate**
```bash
# Using Let's Encrypt
sudo certbot --nginx -d your-domain.com
```

2. **Configure SSL**
```bash
# Generate self-signed certificate (development only)
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
```

## Database Setup

### Production Database

1. **Create database and user**
```sql
CREATE DATABASE permit_management_prod;
CREATE USER permit_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE permit_management_prod TO permit_user;
```

2. **Configure connection pooling**
```properties
# application.properties
database.pool.size=20
database.pool.maxLifetime=1800000
database.pool.connectionTimeout=30000
database.pool.idleTimeout=600000
```

3. **Run migrations**
```bash
./gradlew :server:run --args="--migrate"
```

### Backup Strategy

1. **Automated backups**
```bash
# Add to crontab
0 2 * * * /path/to/backup-script.sh
```

2. **Backup script**
```bash
#!/bin/bash
# backup-script.sh
DATE=$(date +%Y%m%d_%H%M%S)
pg_dump permit_management_prod > backup_${DATE}.sql
gzip backup_${DATE}.sql
# Upload to cloud storage
aws s3 cp backup_${DATE}.sql.gz s3://your-backup-bucket/
```

## Monitoring Setup

### Health Checks

The application provides several health check endpoints:

- `GET /health` - Overall system health
- `GET /health/ready` - Readiness probe
- `GET /health/live` - Liveness probe

### Logging Configuration

1. **Configure logback**
```xml
<!-- logback.xml -->
<configuration>
    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>logs/application.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>logs/application.%d{yyyy-MM-dd}.%i.log.gz</fileNamePattern>
            <maxFileSize>100MB</maxFileSize>
            <maxHistory>30</maxHistory>
        </rollingPolicy>
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>
    
    <root level="INFO">
        <appender-ref ref="FILE"/>
    </root>
</configuration>
```

2. **Set up log rotation**
```bash
# /etc/logrotate.d/permit-management
/var/log/permit-management/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 permit permit
    postrotate
        systemctl reload permit-management
    endscript
}
```

### Performance Monitoring

1. **Application metrics**
```bash
# Enable JMX monitoring
java -Dcom.sun.management.jmxremote \
     -Dcom.sun.management.jmxremote.port=9999 \
     -Dcom.sun.management.jmxremote.authenticate=false \
     -Dcom.sun.management.jmxremote.ssl=false \
     -jar server-all.jar
```

2. **Database monitoring**
```sql
-- Monitor active connections
SELECT count(*) FROM pg_stat_activity WHERE state = 'active';

-- Monitor slow queries
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;
```

## Security Configuration

### Environment Variables

```bash
# Production environment variables
export ENVIRONMENT=production
export JWT_SECRET=your-super-secure-jwt-secret-key-min-32-chars
export BCRYPT_ROUNDS=12
export CORS_ORIGINS=https://your-domain.com
export RATE_LIMIT_ENABLED=true
export RATE_LIMIT_REQUESTS=1000
export RATE_LIMIT_WINDOW=3600
```

### Security Headers

The application automatically sets security headers:
- `X-Frame-Options: DENY`
- `X-Content-Type-Options: nosniff`
- `X-XSS-Protection: 1; mode=block`
- `Strict-Transport-Security: max-age=31536000`

### Input Validation

All API endpoints validate input:
- Email format validation
- Password strength requirements
- File type and size validation
- SQL injection prevention

## Scaling

### Horizontal Scaling

1. **Load balancer configuration**
```nginx
upstream permit_backend {
    server 127.0.0.1:8080;
    server 127.0.0.1:8081;
    server 127.0.0.1:8082;
}

server {
    location / {
        proxy_pass http://permit_backend;
    }
}
```

2. **Session management**
```bash
# Use Redis for session storage
export SESSION_STORE=redis
export REDIS_URL=redis://localhost:6379
```

### Database Scaling

1. **Read replicas**
```bash
# Configure read-only replicas
export READ_DATABASE_URL=jdbc:postgresql://read-replica:5432/permit_management_prod
export WRITE_DATABASE_URL=jdbc:postgresql://master:5432/permit_management_prod
```

2. **Connection pooling**
```properties
# Optimize connection pool
database.pool.size=50
database.pool.maxLifetime=1800000
database.pool.connectionTimeout=30000
```

## Troubleshooting

### Common Issues

1. **Database connection errors**
```bash
# Check database connectivity
psql -h localhost -U permit_user -d permit_management_prod -c "SELECT 1;"
```

2. **Memory issues**
```bash
# Monitor memory usage
jstat -gc <pid> 1s
```

3. **Port conflicts**
```bash
# Check port usage
netstat -tlnp | grep :8080
```

### Log Analysis

1. **Application logs**
```bash
# Monitor application logs
tail -f logs/application.log | grep ERROR
```

2. **Access logs**
```bash
# Monitor access logs
tail -f /var/log/nginx/access.log | grep permit-management
```

## Deployment Checklist

### Pre-deployment
- [ ] Database migrations tested
- [ ] Environment variables configured
- [ ] SSL certificates installed
- [ ] Backup strategy implemented
- [ ] Monitoring configured

### Deployment
- [ ] Application built and tested
- [ ] Database schema updated
- [ ] Application deployed
- [ ] Health checks passing
- [ ] Load balancer configured

### Post-deployment
- [ ] Application accessible
- [ ] API endpoints responding
- [ ] Monitoring alerts configured
- [ ] Backup verification
- [ ] Performance testing completed

## Rollback Procedure

1. **Stop the application**
```bash
systemctl stop permit-management
```

2. **Restore previous version**
```bash
# Restore from backup
cp backup/server-all.jar server/build/libs/
```

3. **Restart the application**
```bash
systemctl start permit-management
```

4. **Verify functionality**
```bash
curl http://localhost:8080/health
```
