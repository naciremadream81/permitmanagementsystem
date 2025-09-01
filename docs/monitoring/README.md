# Monitoring Guide

## Overview

The Permit Management System includes comprehensive monitoring capabilities to ensure system health, performance, and reliability. This guide covers monitoring setup, configuration, and best practices.

## Monitoring Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │    │   Health Checks │    │   Logging       │
│   Metrics       │    │   Endpoints     │    │   System        │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────┴─────────────┐
                    │    Monitoring Stack       │
                    │  (Health + Logs + Metrics)│
                    └─────────────┬─────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │     Alerting System       │
                    │  (Email + Slack + Webhook)│
                    └───────────────────────────┘
```

## Health Monitoring

### Health Check Endpoints

The application provides several health check endpoints for monitoring:

#### Basic Health Check
```bash
curl http://localhost:8080/health
```

**Response:**
```json
{
  "success": true,
  "data": {
    "status": "HEALTHY",
    "timestamp": "2025-01-01T00:00:00Z",
    "uptime": 3600000,
    "version": "1.0.0",
    "environment": "production",
    "components": [
      {
        "name": "system_resources",
        "status": "HEALTHY",
        "message": "System resources are healthy",
        "responseTime": 5,
        "details": {
          "memory_usage_percent": "45",
          "total_memory_mb": "2048",
          "used_memory_mb": "921",
          "free_memory_mb": "1127",
          "available_processors": "4"
        }
      }
    ],
    "metrics": {
      "uptime_seconds": "3600",
      "total_requests": "1250",
      "total_errors": "5"
    }
  }
}
```

#### Readiness Probe
```bash
curl http://localhost:8080/health/ready
```

**Response:**
```json
{
  "success": true,
  "data": {
    "ready": true
  },
  "message": "System is ready"
}
```

#### Liveness Probe
```bash
curl http://localhost:8080/health/live
```

**Response:**
```json
{
  "success": true,
  "data": {
    "alive": true
  },
  "message": "System is alive"
}
```

### Health Check Components

The system monitors several components:

1. **System Resources**
   - Memory usage
   - CPU utilization
   - Available processors
   - Disk space

2. **Database Connectivity**
   - Connection pool status
   - Query response times
   - Connection errors

3. **Application Health**
   - Request counts
   - Error rates
   - Response times

## Logging System

### Structured Logging

The application uses structured logging with consistent format:

```json
{
  "timestamp": "2025-01-01T00:00:00Z",
  "level": "INFO",
  "message": "API Request",
  "service": "permit-management-system",
  "version": "1.0.0",
  "environment": "production",
  "traceId": "abc123def456",
  "spanId": "span789",
  "userId": "user123",
  "requestId": "req456",
  "endpoint": "/api/packages",
  "method": "GET",
  "statusCode": 200,
  "duration": 150,
  "metadata": {
    "user_agent": "Mozilla/5.0...",
    "remote_host": "192.168.1.100"
  }
}
```

### Log Levels

- **TRACE**: Detailed debugging information
- **DEBUG**: General debugging information
- **INFO**: General information about system operation
- **WARN**: Warning messages for potential issues
- **ERROR**: Error messages for failed operations
- **FATAL**: Critical errors that may cause system failure

### Log Categories

1. **Application Logs**
   - API requests and responses
   - Business logic execution
   - User actions

2. **System Logs**
   - Startup and shutdown
   - Configuration changes
   - System events

3. **Error Logs**
   - Exceptions and stack traces
   - Failed operations
   - System errors

4. **Security Logs**
   - Authentication events
   - Authorization failures
   - Security violations

## Monitoring Setup

### Automated Monitoring

The system includes automated monitoring scripts:

#### Health Check Script
```bash
# Run health check
./extra/scripts/health-checks/application-health.sh
```

**Features:**
- Comprehensive system health check
- Component status validation
- Performance metrics collection
- Alert generation

#### Monitoring Configuration
```bash
# Setup monitoring
./extra/scripts/setup-monitoring.sh
```

**Creates:**
- Health check scripts
- Alerting configuration
- Report generation tools
- Cron job setup

### Manual Monitoring

#### System Metrics
```bash
# Check system resources
curl http://localhost:8080/health | jq '.data.components[] | select(.name=="system_resources")'

# Check database status
curl http://localhost:8080/health | jq '.data.components[] | select(.name=="database")'
```

#### Application Metrics
```bash
# Check request counts
curl http://localhost:8080/health | jq '.data.metrics'

# Check error rates
curl http://localhost:8080/health | jq '.data.components[] | select(.name=="application")'
```

## Alerting System

### Alert Channels

The monitoring system supports multiple alert channels:

1. **Email Alerts**
   ```bash
   # Send email alert
   ./extra/scripts/alerts/send-alert.sh -m "System health check failed" -s CRITICAL -c email
   ```

2. **Slack Alerts**
   ```bash
   # Send Slack alert
   ./extra/scripts/alerts/send-alert.sh -m "High memory usage detected" -s WARNING -c slack
   ```

3. **Webhook Alerts**
   ```bash
   # Send webhook alert
   ./extra/scripts/alerts/send-alert.sh -m "Database connection failed" -s CRITICAL -c webhook
   ```

### Alert Severity Levels

- **INFO**: Informational messages
- **WARNING**: Potential issues that need attention
- **CRITICAL**: Serious issues requiring immediate action

### Alert Configuration

#### Email Configuration
```bash
# Set email recipient
export ALERT_EMAIL="admin@example.com"

# Test email alert
./extra/scripts/alerts/send-alert.sh -m "Test alert" -s INFO -c email
```

#### Slack Configuration
```bash
# Set Slack webhook URL
export SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"

# Test Slack alert
./extra/scripts/alerts/send-alert.sh -m "Test alert" -s INFO -c slack
```

#### Webhook Configuration
```bash
# Set webhook URL
export WEBHOOK_URL="https://your-monitoring-system.com/webhook"

# Test webhook alert
./extra/scripts/alerts/send-alert.sh -m "Test alert" -s INFO -c webhook
```

## Performance Monitoring

### Key Metrics

1. **Response Times**
   - API endpoint response times
   - Database query performance
   - File upload/download speeds

2. **Throughput**
   - Requests per second
   - Concurrent users
   - Data processing rates

3. **Resource Usage**
   - Memory consumption
   - CPU utilization
   - Disk I/O
   - Network bandwidth

4. **Error Rates**
   - HTTP error rates
   - Database error rates
   - Application exceptions

### Performance Thresholds

```bash
# Configure performance thresholds
export PERFORMANCE_THRESHOLDS=(
    "response_time_ms:1000"
    "memory_usage_mb:1000"
    "error_rate_percent:5"
    "cpu_usage_percent:80"
)
```

### Performance Monitoring Scripts

#### System Performance Check
```bash
# Check system performance
./extra/scripts/health-checks/application-health.sh

# Output includes:
# - Memory usage percentage
# - CPU utilization
# - Response times
# - Error rates
```

#### Database Performance
```sql
-- Monitor database performance
SELECT 
    query,
    mean_time,
    calls,
    total_time
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;
```

## Log Analysis

### Log Aggregation

The system provides tools for log analysis:

#### Generate Monitoring Report
```bash
# Generate comprehensive report
./extra/scripts/reports/generate-report.sh
```

**Report includes:**
- System health status
- Performance metrics
- Component status
- Error summaries

#### Log Analysis Tools
```bash
# Analyze application logs
tail -f logs/application.log | grep ERROR

# Monitor access logs
tail -f logs/access.log | grep "POST /api/"

# Check error patterns
grep "ERROR" logs/application.log | tail -20
```

### Log Rotation

Configure log rotation to manage disk space:

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

## Dashboard and Reporting

### Monitoring Dashboard

The system generates HTML reports for monitoring:

#### Generate Dashboard
```bash
# Generate monitoring dashboard
./extra/scripts/reports/generate-report.sh
```

**Dashboard includes:**
- System health overview
- Performance metrics
- Component status
- Error summaries
- Historical trends

#### Dashboard Features
- Real-time system status
- Performance metrics visualization
- Component health indicators
- Error rate monitoring
- Resource usage tracking

### Custom Reports

#### Create Custom Report
```bash
# Create custom monitoring report
cat > custom-report.sh << 'EOF'
#!/bin/bash
echo "=== Custom Monitoring Report ==="
echo "Date: $(date)"
echo "System Status: $(curl -s http://localhost:8080/health | jq -r '.data.status')"
echo "Memory Usage: $(curl -s http://localhost:8080/health | jq -r '.data.components[] | select(.name=="system_resources") | .details.memory_usage_percent')%"
echo "Total Requests: $(curl -s http://localhost:8080/health | jq -r '.data.metrics.total_requests')"
EOF

chmod +x custom-report.sh
./custom-report.sh
```

## Troubleshooting

### Common Issues

1. **Health Check Failures**
   ```bash
   # Check specific component
   curl http://localhost:8080/health | jq '.data.components[] | select(.status != "HEALTHY")'
   
   # Check system resources
   free -h
   df -h
   top
   ```

2. **High Memory Usage**
   ```bash
   # Check memory usage
   curl http://localhost:8080/health | jq '.data.components[] | select(.name=="system_resources")'
   
   # Check Java heap
   jstat -gc <pid> 1s
   ```

3. **Database Issues**
   ```bash
   # Check database connectivity
   psql -h localhost -U permit_user -d permit_management_prod -c "SELECT 1;"
   
   # Check connection pool
   curl http://localhost:8080/health | jq '.data.components[] | select(.name=="database")'
   ```

### Debugging Tools

1. **Application Logs**
   ```bash
   # Monitor application logs
   tail -f logs/application.log
   
   # Filter by log level
   tail -f logs/application.log | grep "ERROR\|WARN"
   ```

2. **System Monitoring**
   ```bash
   # Monitor system resources
   htop
   
   # Monitor network
   netstat -tlnp | grep :8080
   
   # Monitor disk usage
   iostat -x 1
   ```

## Best Practices

### Monitoring Strategy

1. **Proactive Monitoring**
   - Set up automated health checks
   - Configure alerting thresholds
   - Monitor key performance indicators
   - Track business metrics

2. **Alert Management**
   - Use appropriate severity levels
   - Avoid alert fatigue
   - Implement escalation procedures
   - Regular alert testing

3. **Log Management**
   - Use structured logging
   - Implement log rotation
   - Monitor log volume
   - Regular log analysis

### Performance Optimization

1. **Resource Monitoring**
   - Monitor memory usage trends
   - Track CPU utilization patterns
   - Monitor disk I/O performance
   - Watch network bandwidth usage

2. **Application Monitoring**
   - Track response time trends
   - Monitor error rates
   - Watch for performance degradation
   - Identify bottlenecks

### Security Monitoring

1. **Security Events**
   - Monitor authentication failures
   - Track authorization violations
   - Watch for suspicious activity
   - Log security-related events

2. **Access Monitoring**
   - Monitor API access patterns
   - Track user activity
   - Watch for unusual behavior
   - Log access attempts

## Integration with External Tools

### Prometheus Integration

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'permit-management'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: '/health'
    scrape_interval: 30s
```

### Grafana Dashboard

```json
{
  "dashboard": {
    "title": "Permit Management System",
    "panels": [
      {
        "title": "System Health",
        "type": "stat",
        "targets": [
          {
            "expr": "up{job=\"permit-management\"}"
          }
        ]
      }
    ]
  }
}
```

### ELK Stack Integration

```yaml
# logstash.conf
input {
  file {
    path => "/var/log/permit-management/*.log"
    codec => "json"
  }
}

filter {
  if [level] == "ERROR" {
    mutate {
      add_tag => ["error"]
    }
  }
}

output {
  elasticsearch {
    hosts => ["localhost:9200"]
    index => "permit-management-%{+YYYY.MM.dd}"
  }
}
```

This monitoring guide provides comprehensive coverage of the Permit Management System's monitoring capabilities. Use these tools and practices to ensure system reliability, performance, and availability.
