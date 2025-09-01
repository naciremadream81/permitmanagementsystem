# Construction Industry Permit Management System - Deployment Guide

This guide covers deploying the enhanced Permit Package Manager for the construction industry, with options for both AWS cloud deployment and self-hosted Docker deployment.

## System Overview

The enhanced system includes:
- **Project Phase Management**: Track construction phases (Foundation, Framing, Electrical, etc.)
- **Inspection Tracking**: Schedule and manage required inspections
- **Fee Management**: Track permit fees and payments
- **County-Specific Features**: Dynamic checklists and permit types
- **Document Management**: Enhanced file handling with approval workflows
- **Real-time Updates**: WebSocket support for live status updates

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile Apps   │    │   Web Interface │    │   Desktop Apps  │
│  (iOS/Android)  │    │                 │    │ (Windows/Linux) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Load Balancer │
                    │   (NGINX/ALB)   │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Backend API    │
                    │ (Kotlin + Ktor) │
                    └─────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  PostgreSQL DB  │    │   File Storage  │    │   Redis Cache   │
│                 │    │   (S3/MinIO)    │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Option 1: AWS Cloud Deployment (Recommended for Production)

### Prerequisites
- AWS Account with appropriate permissions
- AWS CLI configured
- Docker and Docker Compose installed locally
- Domain name (optional but recommended)

### 1.1 Infrastructure Setup with AWS CDK

Create `infrastructure/aws-cdk/` directory:

```typescript
// infrastructure/aws-cdk/lib/permit-management-stack.ts
import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';

export class PermitManagementStack extends cdk.Stack {
  constructor(scope: cdk.App, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // VPC
    const vpc = new ec2.Vpc(this, 'PermitVPC', {
      maxAzs: 2,
      natGateways: 1,
    });

    // RDS PostgreSQL
    const database = new rds.DatabaseInstance(this, 'PermitDatabase', {
      engine: rds.DatabaseInstanceEngine.postgres({
        version: rds.PostgresEngineVersion.VER_15,
      }),
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.MICRO),
      vpc,
      databaseName: 'permit_management',
      credentials: rds.Credentials.fromGeneratedSecret('postgres'),
      backupRetention: cdk.Duration.days(7),
      deletionProtection: false, // Set to true for production
    });

    // S3 Bucket for file storage
    const fileBucket = new s3.Bucket(this, 'PermitFiles', {
      versioned: true,
      encryption: s3.BucketEncryption.S3_MANAGED,
      lifecycleRules: [
        {
          id: 'ArchiveOldFiles',
          enabled: true,
          transitions: [
            {
              storageClass: s3.StorageClass.INFREQUENT_ACCESS,
              transitionAfter: cdk.Duration.days(90),
            },
            {
              storageClass: s3.StorageClass.GLACIER,
              transitionAfter: cdk.Duration.days(365),
            },
          ],
        },
      ],
    });

    // ECS Cluster
    const cluster = new ecs.Cluster(this, 'PermitCluster', {
      vpc,
      capacity: {
        instanceType: ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.MICRO),
        desiredCapacity: 1,
        maxCapacity: 3,
      },
    });

    // Application Load Balancer
    const lb = new elbv2.ApplicationLoadBalancer(this, 'PermitALB', {
      vpc,
      internetFacing: true,
    });

    // ECS Service
    const taskDefinition = new ecs.FargateTaskDefinition(this, 'PermitTask', {
      memoryLimitMiB: 1024,
      cpu: 512,
    });

    taskDefinition.addContainer('PermitApp', {
      image: ecs.ContainerImage.fromAsset('../'),
      environment: {
        DATABASE_URL: database.instanceEndpoint.socketAddress,
        DB_USER: 'postgres',
        DB_PASSWORD: database.secret?.secretValueFromJson('password') || '',
        JWT_SECRET: 'your-production-jwt-secret',
        ENVIRONMENT: 'production',
        AWS_S3_BUCKET: fileBucket.bucketName,
      },
      portMappings: [{ containerPort: 8080 }],
      logging: ecs.LogDrivers.awsLogs({ streamPrefix: 'PermitApp' }),
    });

    const service = new ecs.FargateService(this, 'PermitService', {
      cluster,
      taskDefinition,
      desiredCount: 2,
    });

    // Target Group
    const targetGroup = new elbv2.ApplicationTargetGroup(this, 'PermitTargetGroup', {
      vpc,
      port: 8080,
      protocol: elbv2.ApplicationProtocol.HTTP,
      targetType: elbv2.TargetType.IP,
      healthCheck: {
        path: '/health',
        healthyHttpCodes: '200',
      },
    });

    targetGroup.addTarget(service);

    // Listener
    lb.addListener('PermitListener', {
      port: 80,
      defaultTargetGroups: [targetGroup],
    });

    // Outputs
    new cdk.CfnOutput(this, 'LoadBalancerDNS', {
      value: lb.loadBalancerDnsName,
    });

    new cdk.CfnOutput(this, 'DatabaseEndpoint', {
      value: database.instanceEndpoint.hostname,
    });

    new cdk.CfnOutput(this, 'S3BucketName', {
      value: fileBucket.bucketName,
    });
  }
}
```

### 1.2 Deploy Infrastructure

```bash
# Install AWS CDK
npm install -g aws-cdk

# Bootstrap CDK (first time only)
cdk bootstrap

# Deploy infrastructure
cd infrastructure/aws-cdk
cdk deploy
```

### 1.3 Application Deployment

Create production Dockerfile:

```dockerfile
# Dockerfile.production
FROM openjdk:17-jdk-slim

WORKDIR /app

# Copy application JAR
COPY server/build/libs/server-*.jar app.jar

# Copy configuration
COPY server/src/main/resources/application.conf /app/

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Run application
CMD ["java", "-jar", "app.jar"]
```

Deploy to ECS:

```bash
# Build and push Docker image
docker build -f Dockerfile.production -t permit-management:latest .
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com
docker tag permit-management:latest $AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/permit-management:latest
docker push $AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/permit-management:latest

# Update ECS service
aws ecs update-service --cluster PermitCluster --service PermitService --force-new-deployment
```

## Option 2: Self-Hosted Docker Deployment

### 2.1 Production Docker Compose

```yaml
# docker-compose.production.yml
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:15-alpine
    container_name: permit_postgres
    environment:
      POSTGRES_DB: permit_management
      POSTGRES_USER: permit_user
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups
    ports:
      - "5432:5432"
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U permit_user -d permit_management"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Redis for caching and sessions
  redis:
    image: redis:7-alpine
    container_name: permit_redis
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  # MinIO for S3-compatible file storage
  minio:
    image: minio/minio:latest
    container_name: permit_minio
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: ${MINIO_ROOT_USER}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD}
    volumes:
      - minio_data:/data
    ports:
      - "9000:9000"
      - "9001:9001"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Application Server
  app:
    build:
      context: .
      dockerfile: Dockerfile.production
    container_name: permit_app
    environment:
      DATABASE_URL: jdbc:postgresql://postgres:5432/permit_management
      DB_USER: permit_user
      DB_PASSWORD: ${DB_PASSWORD}
      JWT_SECRET: ${JWT_SECRET}
      ENVIRONMENT: production
      REDIS_URL: redis://redis:6379
      MINIO_ENDPOINT: http://minio:9000
      MINIO_ACCESS_KEY: ${MINIO_ROOT_USER}
      MINIO_SECRET_KEY: ${MINIO_ROOT_PASSWORD}
      MINIO_BUCKET: permit-files
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      minio:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # NGINX Reverse Proxy
  nginx:
    image: nginx:alpine
    container_name: permit_nginx
    volumes:
      - ./nginx/nginx.production.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - app
    restart: unless-stopped

  # Backup Service
  backup:
    image: postgres:15-alpine
    container_name: permit_backup
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - ./backups:/backups
      - ./scripts:/scripts:ro
    command: >
      sh -c "
        while true; do
          sleep 86400;
          pg_dump -h postgres -U permit_user -d permit_management | gzip > /backups/backup_$(date +%Y%m%d_%H%M%S).sql.gz;
          find /backups -name '*.sql.gz' -mtime +7 -delete;
        done
      "
    depends_on:
      - postgres
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
  minio_data:
```

### 2.2 Production NGINX Configuration

```nginx
# nginx/nginx.production.conf
events {
    worker_connections 1024;
}

http {
    upstream permit_app {
        server app:8080;
    }

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    server {
        listen 80;
        server_name _;
        return 301 https://$host$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name your-domain.com;

        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;

        # API endpoints with rate limiting
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://permit_app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Authentication endpoints with stricter rate limiting
        location /auth/ {
            limit_req zone=login burst=5 nodelay;
            proxy_pass http://permit_app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Static files
        location / {
            proxy_pass http://permit_app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Health check
        location /health {
            access_log off;
            proxy_pass http://permit_app;
        }
    }
}
```

### 2.3 Environment Configuration

```bash
# .env.production
DB_PASSWORD=your-secure-database-password
JWT_SECRET=your-very-long-random-jwt-secret-key
MINIO_ROOT_USER=permit_admin
MINIO_ROOT_PASSWORD=your-secure-minio-password
ENVIRONMENT=production
```

### 2.4 Deployment Scripts

```bash
#!/bin/bash
# deploy-production.sh

set -e

echo "🚀 Deploying Permit Management System to Production..."

# Load environment variables
source .env.production

# Create necessary directories
mkdir -p backups logs nginx/ssl

# Generate SSL certificate (self-signed for testing, use Let's Encrypt for production)
if [ ! -f nginx/ssl/cert.pem ]; then
    echo "📜 Generating self-signed SSL certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout nginx/ssl/key.pem \
        -out nginx/ssl/cert.pem \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
fi

# Build and start services
echo "🔨 Building and starting services..."
docker-compose -f docker-compose.production.yml down
docker-compose -f docker-compose.production.yml build --no-cache
docker-compose -f docker-compose.production.yml up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be healthy..."
sleep 30

# Check service health
echo "🏥 Checking service health..."
docker-compose -f docker-compose.production.yml ps

# Initialize database if needed
echo "🗄️ Initializing database..."
docker-compose -f docker-compose.production.yml exec -T app ./gradlew :server:run --args="--init-db" || true

echo "✅ Deployment completed successfully!"
echo "🌐 Application available at: https://localhost"
echo "📊 MinIO Console: http://localhost:9001"
echo "📝 Logs: docker-compose -f docker-compose.production.yml logs -f"
```

## Option 3: Hybrid Deployment (Recommended for Cost Optimization)

### 3.1 Architecture
- **Database**: AWS RDS (Free Tier eligible)
- **File Storage**: AWS S3 (Free Tier eligible)
- **Application**: Self-hosted Docker
- **CDN**: CloudFront for static assets

### 3.2 Configuration

```yaml
# docker-compose.hybrid.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.production
    environment:
      DATABASE_URL: ${AWS_RDS_ENDPOINT}
      DB_USER: ${AWS_RDS_USERNAME}
      DB_PASSWORD: ${AWS_RDS_PASSWORD}
      AWS_S3_BUCKET: ${AWS_S3_BUCKET}
      AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}
      AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY}
      AWS_REGION: ${AWS_REGION}
      JWT_SECRET: ${JWT_SECRET}
      ENVIRONMENT: production
    ports:
      - "8080:8080"
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    volumes:
      - ./nginx/nginx.hybrid.conf:/etc/nginx/nginx.conf:ro
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - app
    restart: unless-stopped
```

## Monitoring and Maintenance

### 4.1 Health Checks

```bash
#!/bin/bash
# health-check.sh

# Check application health
curl -f http://localhost:8080/health || exit 1

# Check database connectivity
docker-compose exec -T postgres pg_isready -U permit_user || exit 1

# Check disk space
df -h | awk '$5 > "80%" {print "WARNING: Disk usage > 80%"}'

# Check memory usage
free -m | awk 'NR==2{if($3/$2*100 > 80) print "WARNING: Memory usage > 80%"}'
```

### 4.2 Backup Strategy

```bash
#!/bin/bash
# backup.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups"

# Database backup
docker-compose exec -T postgres pg_dump -U permit_user permit_management | gzip > "$BACKUP_DIR/db_backup_$DATE.sql.gz"

# File storage backup (if using local storage)
tar -czf "$BACKUP_DIR/files_backup_$DATE.tar.gz" /app/uploads/

# Cleanup old backups (keep 30 days)
find "$BACKUP_DIR" -name "*.gz" -mtime +30 -delete
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete

echo "Backup completed: $DATE"
```

### 4.3 Log Management

```bash
#!/bin/bash
# log-rotation.sh

# Rotate application logs
logrotate -f /etc/logrotate.d/permit-management

# Compress old logs
find /var/log -name "*.log.*" -mtime +7 -exec gzip {} \;

# Clean up old compressed logs
find /var/log -name "*.log.*.gz" -mtime +30 -delete
```

## Security Considerations

### 5.1 Network Security
- Use VPC with private subnets for database
- Implement security groups with minimal required access
- Use SSL/TLS for all communications
- Implement rate limiting and DDoS protection

### 5.2 Application Security
- Regular security updates for dependencies
- Input validation and sanitization
- SQL injection prevention
- XSS protection
- CSRF tokens for forms

### 5.3 Data Security
- Encrypt data at rest and in transit
- Implement proper access controls
- Regular security audits
- Compliance with industry regulations (HIPAA, SOX, etc.)

## Performance Optimization

### 6.1 Database Optimization
- Proper indexing strategy
- Query optimization
- Connection pooling
- Regular VACUUM and ANALYZE

### 6.2 Application Optimization
- Response caching with Redis
- Static asset CDN
- Gzip compression
- Image optimization

### 6.3 Infrastructure Optimization
- Auto-scaling based on load
- Load balancing
- CDN for global distribution
- Monitoring and alerting

## Cost Optimization

### 7.1 AWS Free Tier
- RDS: 750 hours/month for 12 months
- S3: 5GB storage, 20,000 GET requests, 2,000 PUT requests
- EC2: 750 hours/month for 12 months
- CloudFront: 1TB data transfer out

### 7.2 Self-Hosted Costs
- VPS: $5-20/month
- Domain: $10-15/year
- SSL Certificate: Free (Let's Encrypt)

## Troubleshooting

### 8.1 Common Issues

**Database Connection Issues**
```bash
# Check database status
docker-compose exec postgres pg_isready -U permit_user

# Check logs
docker-compose logs postgres
```

**Application Startup Issues**
```bash
# Check application logs
docker-compose logs app

# Check environment variables
docker-compose exec app env | grep -E "(DATABASE|JWT|AWS)"
```

**File Upload Issues**
```bash
# Check MinIO status
docker-compose exec minio mc admin info local

# Check S3 bucket permissions
aws s3 ls s3://your-bucket-name
```

### 8.2 Performance Issues

**Slow Database Queries**
```sql
-- Enable query logging
ALTER SYSTEM SET log_statement = 'all';
SELECT pg_reload_conf();

-- Check slow queries
SELECT query, mean_time, calls FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;
```

**High Memory Usage**
```bash
# Check memory usage
docker stats

# Check application memory
docker-compose exec app jstat -gc <pid>
```

## Support and Maintenance

### 9.1 Regular Maintenance Tasks
- Weekly: Security updates, log rotation
- Monthly: Database maintenance, backup verification
- Quarterly: Performance review, security audit
- Annually: Infrastructure review, cost optimization

### 9.2 Monitoring Tools
- Application: Prometheus + Grafana
- Infrastructure: AWS CloudWatch or self-hosted monitoring
- Logs: ELK Stack or AWS CloudWatch Logs
- Alerts: Email, Slack, or SMS notifications

### 9.3 Support Contacts
- Development Team: [team@company.com]
- Infrastructure Team: [infra@company.com]
- Emergency Contact: [emergency@company.com]

## Conclusion

This deployment guide provides comprehensive options for deploying the Construction Industry Permit Management System. Choose the option that best fits your:

- **Budget constraints**: Self-hosted is cheapest, AWS is most scalable
- **Technical expertise**: Docker is simpler than AWS CDK
- **Compliance requirements**: Self-hosted gives more control
- **Scalability needs**: AWS provides better auto-scaling

For most construction companies starting out, we recommend the **Hybrid Deployment** option as it provides:
- Low initial costs (AWS Free Tier)
- Professional infrastructure (RDS, S3)
- Easy maintenance (Docker)
- Clear upgrade path to full AWS deployment

Start with the hybrid approach and scale up as your needs grow!
